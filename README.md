# virtualjug-flyers

A small Perl 5 script to create flyers popularizing episodes from [virtualjug.com](http://virtualjug.com/).

Dependencies:

- Modern::Perl
- LWP::UserAgent
- pQuery

Run it something like this:

    perl crawler.pl > virtualjug-`date +%Y-%m-%d`.html

Then use your favorite browser to transform the HTML into PDF.

License: GNU GPL v3

