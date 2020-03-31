package TrawlerConfig;

use Modern::Perl '2020';
use Readonly;
use File::Path qw/make_path/;

Readonly our $DATA_DIR => $ENV{TRAWLER_DATA_DIR} || "$ENV{PWD}/data";
Readonly our $SQL_FILE => "$DATA_DIR/trawl.db";

if (!-e $DATA_DIR) {
  make_path($DATA_DIR);
}

1;
