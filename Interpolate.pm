package Tie::Hash::Interpolate;

use 5.006;
use strict;
use warnings;

use Carp;
use Scalar::Util qw/ looks_like_number blessed /;

our $VERSION = '0.02';

#sub new
#   {
#   my ($class) = @_;
#   my $tied = {};
#   tie %{$tied}, $class;
#   return $tied;
#   }

sub FIRSTKEY
   {
   my $a = scalar keys %{$_[0]->{'_DATA'}};
   return each %{$_[0]->{'_DATA'}};
   }

sub NEXTKEY
   {
   return each %{$_[0]->{'_DATA'}};
   }

sub EXISTS
   {
   return exists $_[0]->{'_DATA'}->{$_[1]};
   }

sub DELETE
   {
   ## force a re-sort on next fetch
   $_[0]->{'_SORT'} = 1;
   delete $_[0]->{'_DATA'}->{$_[1]};
   }

sub CLEAR
   {
   ## force a re-sort on next fetch
   $_[0]->{'_SORT'} = 1;
   %{$_[0]->{'_DATA'}} = ();
   }

sub TIEHASH
   {
   my ($class) = @_;
   my $self = { _DATA => {}, _KEYS => [], _SORT => 1 };
   bless $self, $class;
   }

sub STORE
   {
   my ($self, $key, $val) = @_;

   ## the key must be a number
   croak "key ($key) must be a number" if ref $key ||
      ! looks_like_number($key);

   ## the value must be a number
   croak "val ($val) must be a number" if ref $val ||
      ! looks_like_number($val);

   ## force key to number
   $key += 0;

   ## force a re-sort on next fetch
   $self->{'_SORT'} = 1;

   $self->{'_DATA'}{$key} = $val;

   }

sub FETCH
   {
   my ($self, $key) = @_;

   croak "key ($key) must be a number" if ref $key ||
      ! looks_like_number($key);

   ## force key to number
   $key += 0;

   ## return right away for direct hits
   return $self->{'_DATA'}{$key} if exists $self->{'_DATA'}{$key};

   ## re-sort keys if necessary
   _sort_keys($self) if $self->{'_SORT'};

   my @keys = @{ $self->{'_KEYS'} };

   ## be sure we have at least 2 keys
   croak "cannot interpolate/extrapolate with less than two keys"
      if @keys < 2;

   my ($lower, $upper);

   ## key is below range of known keys
   if ($key < $keys[0])
      {
      ($lower, $upper) = @keys[0, 1];
      }
   ## key is above range of known keys
   elsif ($key > $keys[-1])
      {
      ($lower, $upper) = @keys[-2, -1];
      }
   ## key is within range of known keys
   else
      {

      for my $i (0 .. $#keys - 1)
         {
         ($lower, $upper) = @keys[$i, $i+1];
         last if $key <= $upper;
         croak "unable to find bracketing keys" if $i == $#keys - 1;
         }

      }

   return _mx_plus_b($key, $lower, $upper, $self->{'_DATA'}{$lower},
      $self->{'_DATA'}{$upper});

   }

## sort keys and reset flag
sub _sort_keys
   {
   my ($self) = @_;
   $self->{'_KEYS'} = [ sort { $a <=> $b } keys %{ $self->{'_DATA'} } ];
   $self->{'_SORT'} = 0;
   }

## basic equation for a line given 2 points
sub _mx_plus_b
   {
   my ($x, $x1, $x2, $y1, $y2) = @_;
   my $slope     = ($y2 - $y1) / ($x2 - $x1);
   my $intercept = $y2 - ($slope * $x2);
   return $slope * $x + $intercept;
   }

1;
__END__
=head1 NAME

Tie::Hash::Interpolate - tied mathematical interpolation/extrapolation

=head1 SYNOPSIS

   use Tie::Hash::Interpolate;

   tie my %lut, 'Tie::Hash::Interpolate';

   $lut{3} = 4;
   $lut{5} = 6;

   print $lut{4};  ## prints 5
   print $lut{6};  ## prints 7

=head1 DESCRIPTION

C<Tie::Hash::Interpolate> provides a mechanism for using a hash as a lookup
table for interpolated and extrapolated values.

After your hash is tied, insert your known key-value pairs. If you then fetch a
value that is not a key, an interpolation or extrapolation will be performed as
necessary.

=head1 TO DO

=over 4

=item - support multiple dimenstions

=item - support autovivification of tied hashes

=item - set a per-instance mode for insertion or lookup

=item - set up options to control extrapolation (fatal, constant, simple)

=item - be smarter (proximity based direction) about searching when doing
        interpolation

=back

=head1 AUTHOR

Daniel B. Boorstein, E<lt>danboo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Daniel B. Boorstein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
