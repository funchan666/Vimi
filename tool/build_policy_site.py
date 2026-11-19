"""Render the same policy text used by Flutter into standard public HTML pages."""
from pathlib import Path
from html import escape
import re
import shutil

root=Path(__file__).resolve().parents[1]
out=root/'policy-site/dist';assets=out/'assets';assets.mkdir(parents=True,exist_ok=True)
for source in ['assets/ui/neon-mark.webp','assets/ui/neon-spectrum.webp','assets/fonts/DMSans.ttf','assets/fonts/dmsans-OFL.txt']:
    shutil.copy2(root/source, assets/Path(source).name)
pages=[('privacy','Privacy Policy'),('child-safety','Child safety'),('deletion','Account deletion'),('community','Community guidelines'),('terms','Terms of Use')]
email='funchan7777777@gmail.com'
def linkify(text):
    return escape(text).replace(email,f'<a href="mailto:{email}">{email}</a>')
def shell(title,body,current=''):
    nav=''.join(f'<a href="{slug}.html"'+(' aria-current="page"' if slug==current else '')+f'>{label}</a>' for slug,label in pages[:3])
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)} · Vimi</title><meta name="description" content="Vimi dance community policies, child safety standards and account deletion requests."><link rel="icon" href="assets/neon-mark.webp"><link rel="stylesheet" href="assets/policy.css"></head><body><a class="skip" href="#content">Skip to content</a><header><a class="brand" href="index.html"><img src="assets/neon-mark.webp" width="48" height="48" alt=""><span>vimi</span></a><nav aria-label="Policies">{nav}</nav></header><main id="content">{body}</main><footer><a href="index.html">Vimi safety & privacy</a><a href="mailto:{email}">Contact support</a><a href="assets/dmsans-OFL.txt">Font license</a></footer></body></html>'''
for slug,label in pages:
    groups=(root/f'assets/legal/{slug}.txt').read_text().strip().split('\n\n')
    first=groups.pop(0).splitlines();sections=[];toc=[]
    for group in groups:
        if '\n' not in group and len(group)<72 and group[-1:] not in '.?!':
            anchor=re.sub('[^a-z0-9]+','-',group.lower()).strip('-')
            toc.append(f'<li><a href="#{anchor}">{escape(group)}</a></li>')
            sections.append(f'<h2 id="{anchor}">{escape(group)}</h2>')
        else: sections.append(f'<p>{linkify(group)}</p>')
    date=' '.join(first[1:])
    request=f'<div class="request"><a class="button" href="mailto:{email}?subject=Vimi%20account%20deletion%20request">Email a deletion request</a><p>Use the account email and a short description. Never send your password. No app installation is required.</p></div>' if slug=='deletion' else ''
    contents=f'<aside aria-label="On this page"><p>On this page</p><ul>{"".join(toc)}</ul></aside>' if toc else ''
    body=f'<div class="document-head"><h1>{escape(first[0])}</h1><p class="date">{escape(date)}</p></div>{request}<div class="document">{contents}<article>{"".join(sections)}</article></div>'
    (out/f'{slug}.html').write_text(shell(first[0],body,slug))
links=''.join(f'<li><a href="{slug}.html">{label}</a></li>' for slug,label in pages)
body=f'''<section class="intro"><h1>Keep the floor kind.</h1><p>Read how Vimi handles your data, supports safer dance conversations and gives you control of your account.</p><p>Vimi is a dance community for adults aged 18 and over.</p></section><section class="directory"><h2>Safety & privacy</h2><ul>{links}</ul></section><section class="support"><h2>Need to reach us?</h2><p>Email <a href="mailto:{email}">{email}</a> for support, privacy questions or a deletion request.</p><p>For a content concern, use Report in the app. Do not email suspected illegal imagery. Contact local emergency services if someone is in immediate danger.</p></section>'''
(out/'index.html').write_text(shell('Safety & privacy',body))
(assets/'policy.css').write_text('''@font-face{font-family:DMSans;src:url(DMSans.ttf) format("truetype");font-display:swap}*{box-sizing:border-box}html{color-scheme:dark;scroll-padding-top:2rem}body{margin:0;background:#0c0716;color:#f7f2ff;font:1.0625rem/1.7 DMSans,sans-serif}a{color:#86e7f4;text-underline-offset:.22em}a:hover{color:#f58bdd}a:focus-visible{outline:3px solid #86e7f4;outline-offset:5px;border-radius:4px}::selection{background:#86e7f4;color:#170c24}header,main,footer{max-width:1160px;margin:auto;padding:24px 32px}header{display:flex;justify-content:space-between;align-items:center;gap:24px;flex-wrap:wrap;border-bottom:1px solid #322143}.brand{display:flex;gap:14px;align-items:center;text-decoration:none;color:#f7f2ff;font-size:2rem;font-weight:750;letter-spacing:-.03em}.brand img{border-radius:12px}nav{display:flex;flex-wrap:wrap;gap:12px 24px}nav a{min-height:44px;display:inline-flex;align-items:center;font-size:1rem}nav [aria-current]{color:#f58bdd}h1,h2{font-weight:700;line-height:1.16;text-wrap:balance;letter-spacing:-.025em}h1{font-size:clamp(2.2rem,5vw,3.7rem);max-width:18ch;margin:40px 0 18px}h2{font-size:1.5rem;margin:40px 0 14px;scroll-margin-top:2rem}p{margin:0 0 22px;text-wrap:pretty;overflow-wrap:anywhere}.intro{max-width:730px;padding-bottom:18px}.intro p{font-size:1.2rem;color:#bbb0cd}.directory ul{list-style:none;padding:0;display:grid;grid-template-columns:1fr 1fr;gap:0 40px;max-width:900px}.directory li{border-bottom:1px solid #322143}.directory a{display:block;padding:18px 0;min-height:52px;font-size:1.2rem}.support{max-width:720px;margin-top:24px}.document-head{margin-bottom:30px}.date{color:#bbb0cd}.document{display:grid;grid-template-columns:220px minmax(0,700px);gap:48px;align-items:start}.document article>:first-child{margin-top:0}article{max-width:70ch}aside{position:sticky;top:24px;font-size:1rem}aside p{color:#bbb0cd;margin:0 0 8px}aside ul{padding:0;list-style:none}aside a{display:inline-block;padding:8px 0}footer{display:flex;gap:12px 24px;flex-wrap:wrap;margin-top:64px;border-top:1px solid #322143;font-size:1rem;padding-bottom:40px}.request{max-width:700px;margin-bottom:40px}.request p{color:#bbb0cd;margin-top:16px}.button{display:inline-flex;align-items:center;min-height:52px;padding:12px 24px;border-radius:14px;background:#bba4ff url(neon-spectrum.webp) center/cover;color:#170c24;font-weight:700;text-decoration:none}.button:hover{color:#170c24;filter:brightness(1.08)}.skip{position:absolute;left:-10000px}.skip:focus{left:24px;top:8px;padding:8px;background:#1b122b;z-index:5}@media(max-width:760px){header,main,footer{padding-left:22px;padding-right:22px}.document{display:block}.document aside{position:static;margin-bottom:30px}.directory ul{grid-template-columns:1fr}header{gap:12px}h1{margin-top:28px}nav{gap:8px 18px}}''')
print('Rendered six standard HTML pages from bundled policy text.')
