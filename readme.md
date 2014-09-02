# Cleveland Clinic Laboratories

## Requirements

- Ubuntu/Debian, OSX, Windows
- [Node.js](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)
- Git
    - Ubuntu/Debian: `sudo apt-get install git`
    - Windows/OSX: [SourceTree](http://www.sourcetreeapp.com/)
- Pdftotext
    - Ubuntu/Debian: `sudo apt-get install poppler-utils`
    - OSX: `sudo port install poppler` or `brew install xpdf`
    - Windows: [Xpdf](http://www.foolabs.com/xpdf/download.html).
- [Elasticsearch](http://www.elasticsearch.org)

## Building the site

- `git clone https://github.com/brandonchartier/ccl.git`
- `cd ccl`
- `npm install`
- `npm run build`
- Create `config.json` file with credentials for mail and search
- Install and start the server via [supervisor](http://supervisord.org/)

## Building the search index

- `npm run index` creates the index.json file
    - currently requires internal access

## Search tools

Usage: search [options] [command]

Commands:

    delete
        delete the index

    upload <file>
        upload the index

    *
        search term

Options:

    -h, --help                    output usage information
    -V, --version                 output the version number
    -f, --from [n]                starting offset (defaults to 0)
    -s, --sort [field:direction]  sort by field and direction (asc, desc)
    -t, --type [type]             search by type (pdf, page, test)
    -z, --size [n]                number of hits to return (defaults to 10)

Example:

    $ ./search -t test -z 3 "fish melanoma"
    { title: 'FISH for Cutaneous Melanoma',
      url: 'test/?ID=4803',
      score: 1.7547221 }
    { title: 'FISH for MDM2',
      url: 'test/?ID=4217',
      score: 0.4674486 }
    { title: 'FISH  for PDGFRA',
      url: 'test/?ID=4647',
      score: 0.40067023 }

Rebuild the index:

    $ ./search delete
    $ ./search upload <file...>
