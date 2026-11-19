"""Prepare every frozen Downloads input locally; never publish or register assets."""
import concurrent.futures
import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess

from PIL import Image, ImageCms, ImageOps

ROOT = Path(__file__).resolve().parents[1]
INTAKE = ROOT / 'build/media-intake/2026-11-19/input.json'
STAGING = ROOT / 'ProjectMaterials/Supplied'
ORIGINALS = STAGING / 'Originals'
OUTPUT = STAGING / 'Optimized'
FFMPEG = shutil.which('ffmpeg')
FFPROBE = shutil.which('ffprobe')

CLIPS = [
    ('open-air-group', 'Open-air group routine', 'Groups'),
    ('street-style-group', 'Street-style group take', 'Groups'),
    ('night-plaza-solo', 'Night plaza solo', 'Solo'),
    ('studio-mirror', 'Studio mirror session', 'Solo'),
    ('holiday-duet', 'Holiday duet', 'Duets'),
    ('room-formation', 'Room formation practice', 'Groups'),
    ('evening-plaza-duet', 'Evening plaza duet', 'Duets'),
    ('studio-partner', 'Studio partner sequence', 'Duets'),
    ('group-studio', 'Group studio run', 'Groups'),
    ('hallway-take', 'Hallway close-up take', 'Solo'),
]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(args):
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL,
                   stderr=subprocess.PIPE)


def probe(path):
    return json.loads(subprocess.check_output([
        FFPROBE, '-v', 'error', '-show_format', '-show_streams',
        '-of', 'json', str(path)]))


def video_info(raw):
    video = next(s for s in raw['streams'] if s['codec_type'] == 'video')
    return {
        'width': video['width'], 'height': video['height'],
        'duration': float(raw['format']['duration']),
        'frames': int(video['nb_frames']) if video.get('nb_frames', '').isdigit() else None,
        'fps': video.get('avg_frame_rate'), 'codec': video['codec_name'],
        'audio_tracks': sum(s['codec_type'] == 'audio' for s in raw['streams']),
    }


def backup(item):
    source = Path(item['source'])
    assert source.is_file() and not source.is_symlink(), source
    assert digest(source) == item['sha256'], 'Downloads input changed: ' + source.name
    target = ORIGINALS / source.name
    if not target.exists():
        shutil.copy2(source, target)
    assert digest(target) == item['sha256'], 'Original backup mismatch'
    return target


def prepare_image(item, index):
    source = backup(item)
    name = f'portrait-{index:03d}'
    image_path = OUTPUT / 'portraits' / (name + '.webp')
    thumb_path = OUTPUT / 'thumbnails' / (name + '.webp')
    with Image.open(source) as original:
        image = ImageOps.exif_transpose(original)
        icc = image.info.get('icc_profile')
        if icc:
            image = ImageCms.profileToProfile(
                image, ImageCms.ImageCmsProfile(io.BytesIO(icc)),
                ImageCms.createProfile('sRGB'), outputMode='RGB')
        else:
            image = image.convert('RGB')
        image.thumbnail((960, 1280), Image.Resampling.LANCZOS)
        image.save(image_path, 'WEBP', quality=80, method=6)
        thumb = image.copy()
        thumb.thumbnail((320, 400), Image.Resampling.LANCZOS)
        thumb.save(thumb_path, 'WEBP', quality=78, method=6)
    with Image.open(image_path) as checked:
        checked.load()
        width, height = checked.size
    with Image.open(thumb_path) as checked:
        checked.load()
    # Do not replace a small original with a larger claimed optimization.
    if image_path.stat().st_size + thumb_path.stat().st_size >= source.stat().st_size:
        image_path.unlink()
        image_path = image_path.with_suffix(source.suffix.lower())
        shutil.copy2(source, image_path)
        thumb_path.unlink()
        thumb_path = image_path
        with Image.open(source) as original:
            width, height = ImageOps.exif_transpose(original).size
        encoding = 'Original retained after WebP trial; smaller source wins'
    else:
        # A prior trial may have kept this source instead of the current WebP.
        previous = image_path.with_suffix(source.suffix.lower())
        if previous != image_path:
            previous.unlink(missing_ok=True)
        encoding = 'WebP Q80; oriented sRGB; max 960x1280; thumbnail Q78 max 320x400'
    return {
        **item, 'asset_id': name, 'title': f'Portrait {index:02d}',
        'optimized': str(image_path.relative_to(STAGING)),
        'thumbnail': str(thumb_path.relative_to(STAGING)),
        'optimized_bytes': image_path.stat().st_size,
        'thumbnail_bytes': thumb_path.stat().st_size if thumb_path != image_path else 0,
        'optimized_width': width, 'optimized_height': height,
        'encoding': encoding,
    }


def prepare_video(item, index):
    source = backup(item)
    name, title, group = CLIPS[index]
    target = OUTPUT / 'videos' / (name + '.mp4')
    cover = OUTPUT / 'covers' / (name + '.webp')
    source_info = video_info(probe(source))
    run([FFMPEG, '-hide_banner', '-nostdin', '-loglevel', 'error', '-y',
         '-i', str(source), '-map', '0:v:0', '-map', '0:a?',
         '-vf', 'scale=576:-2:flags=lanczos',
         '-c:v', 'libx264', '-preset', 'slow', '-crf', '27', '-threads', '2',
         '-pix_fmt', 'yuv420p', '-fps_mode', 'passthrough', '-c:a', 'copy',
         '-map_metadata', '-1', '-map_chapters', '-1', '-movflags', '+faststart',
         str(target)])
    encoding = 'H.264 CRF27 slow, width 576 with original aspect, original frame timing, AAC audio copied, faststart'
    if target.stat().st_size >= source.stat().st_size:
        shutil.copy2(source, target)
        encoding = 'Original retained after H.264 trial; smaller source wins'
    actual = video_info(probe(target))
    assert abs(source_info['duration'] - actual['duration']) < .12
    assert actual['width'] <= source_info['width'] and actual['height'] <= source_info['height']
    assert abs(actual['width'] / actual['height'] - source_info['width'] / source_info['height']) < .002
    assert actual['audio_tracks'] == source_info['audio_tracks']
    if source_info['frames'] is not None:
        assert actual['frames'] == source_info['frames'], 'Frame count changed'
    # Full stream decoding catches corrupt tails, not only a readable first frame.
    run([FFMPEG, '-hide_banner', '-nostdin', '-loglevel', 'error',
         '-i', str(target), '-f', 'null', '-'])
    frame = subprocess.check_output([
        FFMPEG, '-hide_banner', '-nostdin', '-loglevel', 'error',
        '-i', str(target), '-frames:v', '1', '-vf', 'scale=384:-2:flags=lanczos',
        '-f', 'image2pipe', '-c:v', 'png', 'pipe:1'])
    with Image.open(io.BytesIO(frame)) as image:
        image.convert('RGB').save(cover, 'WEBP', quality=86, method=6)
    print(f"{name}: {item['bytes']:,} -> {target.stat().st_size:,} bytes; duration/audio/frames retained", flush=True)
    return {
        **item, 'asset_id': name, 'title': title, 'category': group,
        'optimized': str(target.relative_to(STAGING)),
        'thumbnail': str(cover.relative_to(STAGING)),
        'optimized_bytes': target.stat().st_size,
        'thumbnail_bytes': cover.stat().st_size,
        'source_info': source_info, 'optimized_info': actual,
        'encoding': encoding, 'full_decode': 'passed',
    }


def main():
    active = ROOT / 'assets/data/media_library.json'
    if active.exists() and json.loads(active.read_text()).get('version') == 2:
        raise SystemExit('The publisher requested no project media backups. The cloud library is active; local preparation is disabled.')
    assert FFMPEG and FFPROBE, 'ffmpeg and ffprobe are required'
    inputs = json.loads(INTAKE.read_text())
    images = [x for x in inputs if x['kind'] == 'image']
    videos = [x for x in inputs if x['kind'] == 'video']
    assert len(images) == 55 and len(videos) == len(CLIPS) == 10
    for path in [ORIGINALS, OUTPUT / 'portraits', OUTPUT / 'thumbnails',
                 OUTPUT / 'videos', OUTPUT / 'covers']:
        path.mkdir(parents=True, exist_ok=True)
    prepared = [prepare_image(item, i + 1) for i, item in enumerate(images)]
    print('All 55 images compressed and decoded; preparing 10 complete videos.', flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(prepare_video, item, i) for i, item in enumerate(videos)]
        prepared.extend(f.result() for f in futures)
    assert len(prepared) == len(inputs) and {x['id'] for x in prepared} == {x['id'] for x in inputs}
    result = {
        'input_count': len(inputs), 'image_count': len(images), 'video_count': len(videos),
        'source_bytes': sum(x['bytes'] for x in prepared),
        'optimized_bytes': sum(x['optimized_bytes'] + x['thumbnail_bytes'] for x in prepared),
        'rights_status': 'publisher confirmed commercial distribution, likeness and audio rights on 2026-11-19; confirmation is not an independent rights clearance',
        'distribution_status': 'local staging only; not registered in Flutter assets',
        'items': prepared,
    }
    (STAGING / 'prepared.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({key: value for key, value in result.items() if key != 'items'}, indent=2), flush=True)


if __name__ == '__main__':
    main()
