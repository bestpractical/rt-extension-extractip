use strict;
use warnings;

package RT::Action::ExtractIP;
use base qw(RT::Action);

=head1 NAME

RT::Action::ExtractIP

=head1 ARGUMENT

Argument can be used to custom field name and other options. Format
of the argument:

    <cf name>;<option>=<val1>,<val2>;<option>=<val1>,<val2>

=cut

use Regexp::Common qw(net);
use Regexp::Common::net::CIDR ();
use Regexp::IPv6 qw();
use Net::CIDR ();

my $IPv4_mask_re = qr{3[0-2]|[1-2]?[0-9]};
my $IPv4_prefix_check_re = qr{(?<![0-9.])};
my $IPv4_sufix_check_re = qr{(?!\.?[0-9])};
my $IPv4_CIDR_re = qr{
    $IPv4_prefix_check_re
    $RE{net}{CIDR}{IPv4}{-keep}
    $IPv4_sufix_check_re
}x;
my $IPv4_re = qr[
    $IPv4_prefix_check_re
    (?!0\.0\.0\.0)
    ($RE{net}{IPv4})
    (?!/$IPv4_mask_re)
    $IPv4_sufix_check_re
]x;

my $IPv6_mask_re = qr{12[0-8]|1[01][0-9]|[1-9]?[0-9]};
my $IPv6_prefix_check_re = qr{(?<![0-9a-fA-F:.])};
my $IPv6_sufix_check_re = qr{(?!(?:\:{0,2}|\.)[0-9a-fA-F])};
my $IPv6_re = qr[
    $IPv6_prefix_check_re
    ($Regexp::IPv6::IPv6_re)
    (?:/($IPv6_mask_re))?
    $IPv6_sufix_check_re
]x;

my $IP_re = qr{$IPv6_re|$IPv4_re|$IPv4_CIDR_re};

=head2 Commit

Search for IP addresses in the transaction's content.

=cut

sub Commit {
    my $self = shift;
    my $ticket = $self->TicketObj;

    my %args = $self->ParseArgument;

    my $cf = $ticket->LoadCustomFieldByIdentifier( $args{'field'} );
    unless ( $cf && $cf->id ) {
        $RT::Logger->debug("Couldn't find $args{'field'} CF for ticket #". $ticket->id );
        return 1;
    }

    my $how_many_can = $cf->MaxValues;

    my $attach = $self->TransactionObj->ContentObj;
    return 1 unless $attach && $attach->id;

    my %existing;
    for( @{$cf->ValuesForObject( $ticket )->ItemsArrayRef} ) {
        $existing{ $_->Content } =  1;
    }

    if ( $how_many_can && $how_many_can <= keys %existing ) {
        RT->Logger->debug("Ticket #". $ticket->id ." already has maximum number of $args{'field'}, skipping" );
        return 1;
    }

    my $spots_left = $how_many_can - keys %existing;

    my $content = $attach->Content || '';
    while ( $content =~ m/$IP_re/go ) {
        if ( $1 && defined $2 ) { # IPv6/mask
            next if grep lc($_) eq 'cidrv6', @{ $args{'skip'} ||[]};

            my $range = $2 == 128 ? $1 : (Net::CIDR::cidr2range( "$1/$2" ))[0]
                or next;
            $spots_left -= $self->AddIP(
                IP => $range, CustomField => $cf, Skip => \%existing
            );
        }
        elsif ( $1 ) { # IPv6
            next if grep lc($_) eq 'ipv6', @{ $args{'skip'} ||[]};

            $spots_left -= $self->AddIP(
                IP => $1, CustomField => $cf, Skip => \%existing
            );
        }
        elsif ( $3 ) { # IPv4
            next if grep lc($_) eq 'ipv4', @{ $args{'skip'} ||[]};
            $spots_left -= $self->AddIP(
                IP => $3, CustomField => $cf, Skip => \%existing
            );
        }
        elsif ( $4 && defined $5 ) { # IPv4/mask
            next if grep lc($_) eq 'cidrv4', @{ $args{'skip'} ||[]};

            my $cidr = join( '.', map $_||0, (split /\./, $4)[0..3] ) ."/$5";
            my $range = (Net::CIDR::cidr2range( $cidr ))[0] or next;
            $spots_left -= $self->AddIP(
                IP => $range, CustomField => $cf, Skip => \%existing
            );
        }
        return 1 unless $spots_left;
    }

    return 1;
}

sub AddIP {
    my $self = shift;
    my %arg = ( CustomField => undef, IP => undef, Skip => {}, @_ );
    return 0 if !$arg{'IP'} || $arg{'Skip'}->{ $arg{'IP'} }++
        || $arg{'Skip'}->{ $arg{'IP'} .'-'. $arg{'IP'} }++;

    my ($status, $msg) = $self->TicketObj->AddCustomFieldValue(
        Value => $arg{'IP'},
        Field => $arg{'CustomField'},
    );
    RT->Logger->error("Couldn't add IP address: $msg") unless $status;

    return 1;
}

sub ParseArgument {
    my $self = shift;
    my $arg = $self->Argument || '';

    my $field = 'IP';
    ($field, $arg) = split /\s*;\s*/, $arg, 2
        if $arg;

    my %res;
    %res = (%res, map { split /\s*=\s*/, $_ } split /\s*;\s*/, $arg);
    $_ = [ split /\s*,\s*/, $_ ] foreach  %res;
    return %res, field => $field;
}

1;