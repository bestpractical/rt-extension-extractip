#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::ExtractIP::Test tests => undef;
my $test = 'RT::Extension::ExtractIP::Test';

my $queue = $test->load_or_create_queue( Name => 'General' );
ok $queue && $queue->id;

my $cf = $test->create_cf('IP');
ok $cf && $cf->id;

my $scrip = $test->create_scrip;
ok $scrip && $scrip->id;


{
    my $ticket = RT::Ticket->new(RT::SystemUser());
    $ticket->Create(
        Queue => $queue,
        Subject => 'test',
    );
    is $ticket->FirstCustomFieldValue( $cf->Name ), undef,
        "correct value";
    $ticket->Correspond( Content => '192.168.1.1' );

    is $ticket->FirstCustomFieldValue( $cf->Name ), '192.168.1.1',
        "correct value";

    $ticket->Correspond( Content => '192.168.1.2' );
}

done_testing();