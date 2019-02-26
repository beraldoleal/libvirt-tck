#
# Copyright (C) 2009, 2010 Red Hat, Inc.
# Copyright (C) 2009 Daniel P. Berrange
#
# This program is free software; You can redistribute it and/or modify
# it under the GNU General Public License as published by the Free
# Software Foundation; either version 2, or (at your option) any
# later version
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions
#

package Sys::Virt::TCK::NetworkBuilder;

use strict;
use warnings;
use Sys::Virt;

use IO::String;
use XML::Writer;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $self = {
        name => $params{name} ? $params{name} : "tck" ,
    };

    bless $self, $class;

    return $self;
}

sub uuid {
    my $self = shift;

    $self->{uuid} = shift;

    return $self;
}

sub bridge {
    my $self = shift;
    my $name = shift;

    $self->{bridge} = { name => $name,
                        @_ };

    return $self;
}


sub forward {
    my $self = shift;

    $self->{forward} = { @_ };

    return $self;
}

sub interfaces {
    my $self = shift;

    $self->{interfaces} = [@_];

    return $self;
}

sub host_devices {
    my $self = shift;

    $self->{host_devices} = [@_];

    return $self;
}

sub ipaddr {
    my $self = shift;
    my $address = shift;
    my $netmask = shift;

    $self->{ipaddr} = [$address, $netmask];

    return $self;
}

sub bandwidth {
    my $self = shift;
    my %bw = @_;

    $self->{bandwidth} = \%bw;

    return $self;
}

sub dhcp_range {
    my $self = shift;
    my $start = shift;
    my $end = shift;

    $self->{dhcp} = [] unless $self->{dhcp};
    push @{$self->{dhcp}}, [$start, $end];

    return $self;
}

sub as_xml {
    my $self = shift;

    my $data;
    my $fh = IO::String->new(\$data);
    my $w = XML::Writer->new(OUTPUT => $fh,
                             DATA_MODE => 1,
                             DATA_INDENT => 2);
    $w->startTag("network");
    foreach (qw(name uuid)) {
        $w->dataElement("$_" => $self->{$_}) if $self->{$_};
    }

    $w->emptyTag("bridge", %{$self->{bridge}})
        if $self->{bridge};

    if ($self->{bandwidth}) {
	$w->startTag("bandwidth");
	if ($self->{bandwidth}->{"in"}) {
	    $w->emptyTag("inbound", %{$self->{bandwidth}->{"in"}});
	}
	if ($self->{bandwidth}->{"out"}) {
	    $w->emptyTag("outbound", %{$self->{bandwidth}->{"out"}});
	}
	$w->endTag("bandwidth");
    }

    if (exists $self->{forward}) {
	$w->startTag("forward", %{$self->{forward}});
	foreach (@{$self->{interfaces}}) {
	    $w->emptyTag("interface", dev => $_);
	}
	foreach (@{$self->{host_devices}}) {
	    $w->emptyTag("address",
			 type => "pci",
			 domain => $_->[0],
			 bus => $_->[1],
			 slot => $_->[2],
			 function => $_->[3]);
	}
	$w->endTag("forward");
    }

    if ($self->{ipaddr}) {
        $w->startTag("ip",
                     address => $self->{ipaddr}->[0],
                     netmask => $self->{ipaddr}->[1]);

        if ($self->{dhcp}) {
            $w->startTag("dhcp");
            foreach my $range (@{$self->{dhcp}}) {
                $w->emptyTag("range",
                             start => $range->[0],
                             end => $range->[1]);
            }
            $w->endTag("dhcp");
        }

        $w->endTag("ip");
    }
    $w->endTag("network");

    return $data;
}

1;
