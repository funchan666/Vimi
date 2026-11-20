# Vimi safety and privacy website

Extension of Vimi's approved neon system, for reading policies and requesting support.
Design Read: public policy resource; members and reviewers; Read mode; familiar document layout.
Dials: variance 2, motion 1, density 6, asset dependence 3, brand fidelity 10.
Preserve the midnight violet, pink/cyan links and DM Sans from DESIGN.md.
Use the supplied Vimi logo and the existing raster spectrum.

- Logo: dist/assets/vimi-logo.png, copied from app assets/ui/vimi-logo.png.
- Button raster: dist/assets/neon-spectrum.webp, copied from app assets/ui/neon-spectrum.webp.
- Font: dist/assets/DMSans.ttf, with dist/assets/dmsans-OFL.txt.
- Legal text: generated exactly from ../assets/legal/*.txt by ../tool/build_policy_site.py.
- Public navigation and deletion-request email work without account login or app installation.
- No analytics SDK, third-party font, data form or password field. The mail link opens the visitor's mail client; it does not send mail automatically.
