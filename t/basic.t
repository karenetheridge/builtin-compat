use strict;
use warnings;
use Test::More;

my @imports;
BEGIN {
  @imports = qw(
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
  );

}

BEGIN {
  use builtin::compat @imports;

  BEGIN {
    for my $import (@imports) {
      no strict 'refs';
      ok defined &$import, "$import imported from builtin::compat";
    }
  }
}

BEGIN {
  for my $import (@imports) {
    no strict 'refs';
    ok !defined &$import, "$import doesn't exist after end of scope";
  }
}

BEGIN {
  for my $import (@imports) {
    no strict 'refs';
    ok defined &{"builtin::compat::$import"}, "builtin::compat::$import exists";
    ok defined &{"builtin::$import"}, "builtin::$import exists";
  }
}

BEGIN {
  use builtin @imports;

  BEGIN {
    for my $import (@imports) {
      no strict 'refs';
      ok defined &$import, "$import imported from builtin";
    }
  }
}

BEGIN {
  for my $import (@imports) {
    no strict 'refs';
    ok !defined &$import, "$import doesn't exist after end of scope";
  }
}

done_testing;
