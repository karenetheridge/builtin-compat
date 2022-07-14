package builtin::compat;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use namespace::clean ();

sub true ();
sub false ();
sub is_bool ($);
sub weaken ($);
sub unweaken ($);
sub is_weak ($);
sub blessed ($);
sub refaddr ($);
sub reftype ($);
sub created_as_string ($);
sub created_as_number ($);
sub ceil ($);
sub floor ($);
sub trim ($);
sub indexed;

BEGIN { eval { require builtin } }

my @fb = (
  true      => 'sub true () { !!1 }',
  false     => 'sub false () { !!0 }',
  is_bool => <<'END_CODE',
use Scalar::Util ();
sub is_bool ($) {
  my $value = shift;
  return false
    if !defined $value || length ref $value || !Scalar::Util::isdual($value);

  return true
    if $value && $value == 1 && $value eq '1';

  return true
    if !$value && $value == 0 && $value eq '';

  return false;
}
END_CODE
  weaken    => \'Scalar::Util::weaken',
  unweaken  => \'Scalar::Util::unweaken',
  is_weak   => \'Scalar::Util::isweak',
  blessed   => \'Scalar::Util::blessed',
  refaddr   => \'Scalar::Util::refaddr',
  reftype   => \'Scalar::Util::reftype',
  created_as_number => <<'END_CODE',
sub created_as_number ($) {
  my $value = shift;

  return true
    if (
      defined $value
      && !length ref $value
      && !is_bool($value)
      && !utf8::is_utf8($value)
      && length( (my $dummy = '') & $value )
      && 0 + $value eq $value
    );

  return false;
}

END_CODE
  created_as_string => <<'END_CODE',
sub created_as_string ($) {
  my $value = shift;

  return true
    if (
      defined $value
      && !length ref $value
      && !is_bool($value)
      && !created_as_number($value)
    );

  return false;
}
END_CODE
  ceil      => <<'END_CODE',
use POSIX ();
sub ceil ($) {
  goto &POSIX::ceil;
}
END_CODE
  floor     => <<'END_CODE',
use POSIX ();
sub floor ($) {
  goto &POSIX::floor;
}
END_CODE
  trim      => <<'END_CODE',
sub trim ($) {
  my $string = shift;
  s/\A\s+//, s/\s+\z// for $string;
  return $string;
}
END_CODE
  indexed   => <<'END_CODE',
sub indexed {
  my $i = 0;
  map +($i++, $_), @_;
}
END_CODE
);

my @EXPORT_OK;

my $code = '';

no strict 'refs';

while (my ($sub, $fb) = splice @fb, 0, 2) {
  push @EXPORT_OK, $sub;
  if (defined &{'builtin::'.$sub}) {
    *$sub = \&{'builtin::'.$sub};
    next;
  }
  if (ref $fb) {
    my ($mod) = $$fb =~ /\A(.*)::/s;
    (my $file = "$mod.pm") =~ s{::}{/}g;
    require $file;
    die "Unable to find $$fb"
      unless defined &{$$fb};
    *$sub = \&{$$fb};
  }
  else {
    $code .= $fb . "\n";
  }

  *{'builtin::'.$sub} = \&$sub;
}

my $e;
{
  local $@;
  eval "$code; 1" or $e = $@;
}
die $e
  if defined $e;

my %EXPORT_OK = map +($_ => 1), @EXPORT_OK;

our $NO_DISABLE_WARNINGS;
sub import {
  my $class = shift;

  # search for caller that is being compiled. can't just use caller directly,
  # beause it may not be the same level as builtin would use for its lexical
  # exports
  my $caller;
  my $level = 0;
  while (my @caller = caller(++$level)) {
    if ($caller[3] =~ /\A(.*)::BEGIN\z/s) {
      $caller = $1;
      last;
    }
  }
  if (!defined $caller) {
    require Carp;
    Carp::croak("builtin::compat::import can only be called at compile time");
  }

  for my $import (@_) {
    require Carp;
    Carp::croak("'$import' is not recognised as a builtin function")
      if !$EXPORT_OK{$import};
    *{$caller.'::'.$import} = \&$import;
  }

  unless ($NO_DISABLE_WARNINGS) {
    local $@;
    eval { warnings->unimport('experimental::builtin') };
  }
  namespace::clean->import(-cleanee => $caller, @_);
  return;
}

if (!defined &builtin::import) {
  *builtin::import = sub {
    local $NO_DISABLE_WARNINGS = 1;
    &import;
  };
}

$INC{'builtin.pm'} ||= __FILE__;

1;
__END__

=head1 NAME

builtin::compat - Provide builtin functions for older perl versions

=head1 SYNOPSIS

  use builtin::compat qw(
    true
    false
    is_bool
    weaken
    unweaken
    is_weak
    blessed
    refaddr
    reftype
    created_as_string
    created_as_number
    ceil
    floor
    trim
    indexed
  );

=head1 DESCRIPTION

Provides L<builtin> functions for perl versions that do not include the
L<builtin> module.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2022 the builtin::compat L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
