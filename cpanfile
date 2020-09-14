requires 'HTTP::Lite'                 => '0';
requires 'Net::GitHub'                => '0';
requires 'Mojo::SQLite'               => '0';
requires 'Mojolicious'                => '0';
requires 'Modern::Perl'               => '0';
requires 'MIME::Base64'               => '0';
requires 'Readonly'                   => '0';
requires 'Syntax::Keyword::Try'       => '0';
requires 'JSON'                       => '0';
requires 'FindBin'                    => '0';
requires 'XML::TreePP'                => '0';
requires 'DateTime'                   => '0';
requires 'DateTime::Format::Strptime' => '0';
requires 'List::MoreUtils'            => '0';

# This isn't because we use PG=> it's just got a better API.
requires 'Mojo::Pg' => '0';

# For tests
requires 'Test::More' => '0';
