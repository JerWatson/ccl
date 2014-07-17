# Cleveland Clinic Laboratories

## Requirements

- Ubuntu/Debian/OSX
- [Node.js](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)
- git
    - Ubuntu/Debian: `sudo apt-get install git`
- pdftotext
    - Ubuntu/Debian: `sudo apt-get install poppler-utils`
    - OSX: `sudo port install poppler` or `brew install xpdf`

## Building the site

- `git clone https://bchar@bitbucket.org/bchar/ccl.git`
- `cd ccl`
- `npm install`
- `npm run build && npm run search`
- Create `settings.json` file with credentials for mail and search
- `npm start`
