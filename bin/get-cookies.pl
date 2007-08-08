#!/usr/bin/perl -w

use strict;
use warnings;

use Getopt::Long;
use IO::Prompt;

use WWW::Mechanize;

use constant COOKIES => $ENV{VOX_COOKIES} || 'vox_cookies.txt';


my %opts;
GetOptions(
    'email|e=s' => \$opts{email},
);


if (!$opts{email}) {
    $opts{email} = prompt "Email address: ";
}
exit if !$opts{email};

$opts{pw} = prompt "Password for $opts{email}: ", -e => '*';


my $mech = WWW::Mechanize->new;
$mech->cookie_jar({ file => COOKIES(), autosave => 1 });
$mech->get('http://www.vox.com/signin?to=%2F');

$mech->submit_form(
    form_number => 2,
    fields => {
        username => $opts{email},
        password => $opts{pw},
    },
);

## Did it work?
if ($mech->cookie_jar->as_string !~ m{ \b UAID \b }xms) {
    print "Did not login (invalid password?)\n";
}

