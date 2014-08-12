# Cleveland Clinic Laboratories

## Requirements

- Ubuntu/Debian, OSX, Windows
- [Node.js](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)
- git
    - Ubuntu/Debian: `sudo apt-get install git`
    - Windows/OSX: [SourceTree](http://www.sourcetreeapp.com/)
- pdftotext
    - Ubuntu/Debian: `sudo apt-get install poppler-utils`
    - OSX: `sudo port install poppler` or `brew install xpdf`
    - Windows: [Xpdf](http://www.foolabs.com/xpdf/download.html).
- [elasticsearch](http://www.elasticsearch.org)

## Building the site

- `git clone https://bchar@bitbucket.org/bchar/ccl.git`
- `cd ccl`
- `npm install`
- `npm run build`
- Create `config.json` file with credentials for mail and search
- Install and start the server via [pm2](https://github.com/Unitech/pm2)

## Building the search index

- `npm run index` creates the index.json file
    - currently requires internal access, to hit the TIMS database

## Search tools

Usage: search [term] [options]

Options:

    -h, --help                    output usage information
    -V, --version                 output the version number
    -D, --delete                  delete the search index
    -U, --update                  update the search index
    -f, --from [n]                starting offset (defaults to 0)
    -s, --sort [field:direction]  sort by field and direction (asc, desc)
    -t, --type [type]             search by type (pdf, page, test)
    -z, --size [n]                number of hits to return (defaults to 10)

Example:

    $ ./search "fish melanoma" -t test -z 5
    { title: 'FISH for Cutaneous Melanoma',
      url: 'test/?ID=4803',
      score: 1.7547221 }
    { title: 'FISH for MDM2',
      url: 'test/?ID=4217',
      score: 0.4674486 }
    { title: 'FISH  for PDGFRA',
      url: 'test/?ID=4647',
      score: 0.40067023 }
    { title: 'FISH for BCL6 Translocations',
      url: 'test/?ID=4267',
      score: 0.38554507 }
    { title: 'FISH for Myelodysplasia',
      url: 'test/?ID=4205',
      score: 0.38167015 }

Rebuild the index:

    $ ./search -D
    {"acknowledged":true}
    $ ./search -U
    update complete
