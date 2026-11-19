"""Register the complete optimized, publisher-authorized set in this Flutter app."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
STAGING = ROOT / 'ProjectMaterials/Supplied'


def main():
    rights = json.loads((ROOT / 'docs/media/supplied-media-rights.json').read_text())
    assert rights['status'] == 'publisher_confirmed'
    prepared = json.loads((STAGING / 'prepared.json').read_text())
    catalog = {'version': 1, 'clips': [], 'portraits': []}
    inventory = []
    registered = set()
    for item in prepared['items']:
        paths = {}
        for field in ['optimized', 'thumbnail']:
            relative = Path(item[field]).relative_to('Optimized')
            source = STAGING / item[field]
            destination = ROOT / 'assets/content' / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
            assert source.read_bytes() == destination.read_bytes()
            paths[field] = str(destination.relative_to(ROOT))
            registered.add(paths[field])
        entry = {'id': item['asset_id'], 'title': item['title'],
                 'asset': paths['optimized'], 'thumbnail': paths['thumbnail']}
        if item['kind'] == 'video':
            entry.update(category=item['category'],
                         duration=item['optimized_info']['duration'],
                         has_audio=item['optimized_info']['audio_tracks'] > 0)
            catalog['clips'].append(entry)
            route = 'Studio → Explore the dance video library → ' + item['title']
        else:
            catalog['portraits'].append(entry)
            route = 'Me → Edit dance profile → Browse profile images → ' + item['title']
        inventory.append({**item, 'runtime': paths, 'reachable_route': route,
                          'rights': 'publisher_confirmed',
                          'runtime_sha256': hashlib.sha256((ROOT / paths['optimized']).read_bytes()).hexdigest()})
    assert len(catalog['portraits']) == 55 and len(catalog['clips']) == 10
    assert len({item['id'] for item in inventory}) == prepared['input_count'] == 65
    actual = {str(p.relative_to(ROOT)) for p in (ROOT / 'assets/content').rglob('*') if p.is_file()}
    assert registered == actual, 'Unreferenced or missing runtime media'
    (ROOT / 'assets/data/media_library.json').write_text(json.dumps(catalog, indent=2) + '\n')
    report = {**{k: v for k, v in prepared.items() if k != 'items'},
              'distribution_status': 'all 65 source items registered in local Flutter media library; no cloud seed users or posts',
              'runtime_files': len(registered),
              'runtime_bytes': sum((ROOT / path).stat().st_size for path in registered),
              'items': inventory}
    (ROOT / 'docs/media/supplied-media-inventory.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'items'}, indent=2))


if __name__ == '__main__':
    main()
