# Contributing

Thanks for helping make the Box_Flasher project better. This file outlines a minimal workflow for contributing changes and keeping the repository size manageable.

1. Fork the repository and create a feature branch (name it something meaningful):

   git checkout -b feat/your-change

2. Make small, focused commits.

3. Run the verification script locally (quick tests and build):

   ./tests/test.sh

4. Stage your changes and commit:

   git add -A
   git commit -m "feat: short message describing change"

5. Ensure you didn't accidentally stage binary blobs bigger than 50MB. Use:

   git ls-files -z | xargs -0 du -sh | sort -hr | head -n 20

6. Push your branch and open a PR:

   git push origin feat/your-change

7. Avoid committing large disk images or tarballs. Instead, use the `data/cache` or `data/downloaded` folder, or a release artifact with GitHub Releases.

Large files: if you need to distribute a disk image or firmware bundle to end users, prefer:
- GitHub Releases (upload image as a release asset)
- External storage (object storage or file share) and store manifest files in the repo
- Git LFS for large assets that must live in the repository
