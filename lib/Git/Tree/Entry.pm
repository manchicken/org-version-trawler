package Git::Tree::Entry;

use Modern::Perl '2020';
use Carp qw/confess/;

use Net::GitHub::V3;
use MIME::Base64 qw/decode_base64/;

sub new {
  my ($pkg, $data) = @_;

  my $self = { ref $data eq 'HASH' ? %$data : () };

  return bless $self, $pkg;
}

sub content {
  my ($self) = @_;

  my $content_deets = $self->{gh}->repos->get_content($self->{path});

  if ($content_deets->{type} ne 'file') {
    confess "Content is a «$content_deets->{type}», not 'file'.";
    return;
  }
  if ($content_deets->{encoding} ne 'base64') {
    confess "Cannot decode content encoding «$content_deets->{encoding}».";
    return;
  }

  return decode_base64($content_deets->{content});
}

1;
