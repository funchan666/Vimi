"""Build Vimi's static website and render the legal text shared with Flutter."""
import json
import re
import shutil
from html import escape
from pathlib import Path
from urllib.parse import quote, urlencode

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "policy-site"
OUTPUT = SITE / "dist"
ASSETS = OUTPUT / "assets"
EMAIL = "funchan7777777@gmail.com"
DELETION_SUBJECT = "Vimi account deletion request"
DELETION_URL = "mailto:" + EMAIL + "?" + urlencode(
    {"subject": DELETION_SUBJECT}, quote_via=quote
)
PAGES = {
    "privacy": ("Privacy Policy", "What Vimi collects, why we use it and how to manage your data."),
    "child-safety": ("Child Safety Standards", "Vimi’s standards against child exploitation and how to report concerns."),
    "deletion": ("Account deletion", "Delete your Vimi account or request deletion by email."),
    "community": ("Community Guidelines", "The rules for sharing covers and connecting with dancers on Vimi."),
    "terms": ("Terms of Use", "The terms for using the Vimi dance community."),
}
TOP_NAV = ("privacy", "child-safety", "deletion")


def nav_link(slug, label, current=None):
    active = ' aria-current="page"' if slug == current else ""
    return f'<a href="{slug}.html"{active}>{escape(label)}</a>'


def shell(title, description, body, current="index"):
    navigation = "".join(nav_link(slug, PAGES[slug][0], current) for slug in TOP_NAV)
    footer_links = "".join(nav_link(slug, label, current) for slug, (label, _) in PAGES.items())
    home_active = ' aria-current="page"' if current == "index" else ""
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="{escape(description)}">
  <meta name="theme-color" content="#100b24">
  <meta property="og:title" content="{escape(title)}">
  <meta property="og:description" content="{escape(description)}">
  <title>{escape(title)}</title>
  <link rel="icon" href="assets/vimi-logo.png">
  <link rel="stylesheet" href="assets/policy.css">
</head>
<body class="{current}">
  <a class="skip-link" href="#content">Skip to content</a>
  <header class="site-header">
    <div class="wrap header-inner">
      <a class="brand" href="index.html"{home_active}>
        <img src="assets/vimi-logo.png" width="48" height="48" alt="">
        <span>Vimi</span>
      </a>
      <nav class="header-nav" aria-label="Policies">{navigation}</nav>
    </div>
  </header>
  <main id="content" tabindex="-1">{body}</main>
  <footer class="site-footer">
    <div class="wrap footer-inner">
      <div class="footer-contact">
        <a href="index.html" class="footer-brand">Vimi</a>
        <a href="mailto:{EMAIL}">Contact support</a>
      </div>
      <div>
        <nav class="footer-nav" aria-label="All policies">{footer_links}</nav>
        <a class="font-license" href="assets/dmsans-OFL.txt">Font license</a>
      </div>
    </div>
  </footer>
</body>
</html>
"""


def library_cover(catalog, clip_id):
    clip = next(item for item in catalog["clips"] if item["id"] == clip_id)
    return escape(catalog["resources"][clip["thumbnail"]]["url"])


def home(catalog):
    group = library_cover(catalog, "open-air-group")
    mirror = library_cover(catalog, "studio-mirror")
    duet = library_cover(catalog, "holiday-duet")
    policy_links = "\n".join(
        f"""<li><a href="{slug}.html"><strong>{escape(label)}</strong>
            <span>{escape(description)}</span></a></li>"""
        for slug, (label, description) in PAGES.items()
    )
    return f"""
    <section class="wrap hero" aria-labelledby="hero-title">
      <div class="hero-copy">
        <h1 id="hero-title">Find your dance crew.</h1>
        <p>Share a K-pop cover, find dancers who move to the same beat and keep track of your practice. Free on Android for adults 18+.</p>
        <a class="button" href="#on-the-floor">Explore Vimi</a>
      </div>
      <figure class="hero-photo">
        <img src="{group}" alt="Dancers rehearsing an outdoor group routine" fetchpriority="high" referrerpolicy="no-referrer">
        <figcaption>Open-air group routine</figcaption>
      </figure>
    </section>
    <section class="floor-band" id="on-the-floor" aria-labelledby="floor-title">
      <div class="wrap floor-layout">
        <div class="floor-copy">
          <h2 id="floor-title">From rehearsal to the floor.</h2>
          <dl>
            <div><dt>Watch and share covers</dt><dd>Browse solo, duet and group clips, then share your own take.</dd></div>
            <div><dt>Stay on beat</dt><dd>Try choreography challenges and save rehearsal notes in your private journal.</dd></div>
            <div><dt>Meet other dancers</dt><dd>Find members by name and follow dancers you like. Mutual follows can message and call.</dd></div>
          </dl>
        </div>
        <div class="floor-photos">
          <figure>
            <img src="{mirror}" alt="Dancer practicing in front of a studio mirror" loading="lazy" decoding="async" referrerpolicy="no-referrer">
            <figcaption>Studio mirror session</figcaption>
          </figure>
          <figure>
            <img src="{duet}" alt="Two dancers performing together" loading="lazy" decoding="async" referrerpolicy="no-referrer">
            <figcaption>Holiday duet</figcaption>
          </figure>
        </div>
      </div>
    </section>
    <section class="wrap policy-directory" aria-labelledby="directory-title">
      <div>
        <h2 id="directory-title">Policies and support.</h2>
        <p>For help with your account, <a href="mailto:{EMAIL}">email Vimi support</a>.</p>
      </div>
      <ul>{policy_links}</ul>
    </section>"""


def paragraph(text, current):
    content = escape(text).replace(EMAIL, f'<a href="mailto:{EMAIL}">{EMAIL}</a>')
    for slug, (label, _) in PAGES.items():
        if slug != current and slug != "deletion":
            content = content.replace(escape(label), nav_link(slug, label))
    return f"<p>{content}</p>"


def policy(slug, description):
    first, *groups = (ROOT / "assets" / "legal" / f"{slug}.txt").read_text().strip().split("\n\n")
    title, date = first.splitlines()
    toc = []
    paragraphs = []
    for block in groups:
        if "\n" not in block and len(block) < 72 and block[-1:] not in ".?!":
            anchor = re.sub("[^a-z0-9]+", "-", block.lower()).strip("-")
            toc.append(f'<li><a href="#{anchor}">{escape(block)}</a></li>')
            paragraphs.append(f'<h2 id="{anchor}" tabindex="-1">{escape(block)}</h2>')
        else:
            paragraphs.append(paragraph(block, slug))
    request = ""
    if slug == "deletion":
        request = f"""
        <section class="request" aria-labelledby="request-title">
          <div>
            <h2 id="request-title">Request by email</h2>
            <p>Include your Vimi account email. Vimi support will verify ownership before deleting the account.</p>
          </div>
          <a class="button" href="{escape(DELETION_URL)}">Email a deletion request</a>
        </section>"""
    body = f"""
      <div class="wrap">
        <header class="document-head">
          <h1>{escape(title)}</h1>
          <p class="date">{escape(date)}</p>
        </header>{request}
        <div class="document">
          <nav class="contents" aria-label="On this page">
            <p>On this page</p>
            <ul>{"".join(toc)}</ul>
          </nav>
          <article aria-label="{escape(title)}">{"".join(paragraphs)}</article>
        </div>
      </div>"""
    return shell(title, description, body, current=slug)


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    for source in (
        ROOT / "assets/ui/vimi-logo.png",
        ROOT / "assets/ui/neon-spectrum.webp",
        ROOT / "assets/ui/neon-floor.webp",
        ROOT / "assets/fonts/DMSans.ttf",
        ROOT / "assets/fonts/dmsans-OFL.txt",
        SITE / "policy.css",
    ):
        shutil.copy2(source, ASSETS / source.name)
    for slug, (_, description) in PAGES.items():
        (OUTPUT / f"{slug}.html").write_text(policy(slug, description), encoding="utf-8")
    catalog = json.loads((ROOT / "assets/data/media_library.json").read_text())
    homepage = shell(
        "Vimi · Find your dance crew",
        "Vimi is a free dance community for adults on Android. Share dance covers, find fellow dancers and keep a practice journal.",
        home(catalog),
    )
    (OUTPUT / "index.html").write_text(homepage, encoding="utf-8")
    print("Rendered the Vimi homepage and five policy pages.")


if __name__ == "__main__":
    main()
