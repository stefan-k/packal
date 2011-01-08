#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;

my $numpath = "tracknum.txt";

my ($add, $delete, $show);
my $result = GetOptions("add=i"    => \$add,
                        "delete=i" => \$delete,
                        "show"     => \$show);

if($add)
{
  print "Adding $add...";
  open my $ADD, ">> $numpath" or die "$numpath: $!";
  print $ADD $add . "\n";
  close $ADD;
  print "Done!\n";
  exit;
} 

if($show)
{
  open my $SHOW, "< $numpath" or die "$numpath: $!";
  print while (<$SHOW>);
  close $SHOW;
  exit;
}

if($delete)
{
  my @numbers;
  open my $DEL, "< $numpath" or die "$numpath: $!";
  while (<$DEL>)
  {
    next if m/^$delete/;
    push @numbers, $_;
  }
  close $DEL;
  open $DEL, "> $numpath" or die "$numpath: $!";
  print $DEL join("", @numbers);
  #print $DEL join @numbers;
  close $DEL;
  exit;
}

my $ua = LWP::UserAgent->new;

open my $FH, "< $numpath" or die "$numpath: $!";

while (<$FH>)
{
  chomp;
  print "Checking Trackingnumber $_...\n";

  my $query = $ua->get("https://nachschau.post.at/SendungsSuche.aspx?lang=de&pnum1=$_");

  die $query->status_line unless $query->is_success;

  if ($query->decoded_content =~ m/divNoResult/)
  {
    print "Number $_ not found!\n";
    next;
  }

  my $parse = 0;

  foreach (split /\n/, $query->decoded_content)
  {
    next unless /gvParcelEventList/ || $parse;
    last if /<\/table>/;
    $parse = 1;
    if (m/<td>(?<status>.+?)<\/td><td>(?<plz>\w+?)<\/td><td>(?<date>.+?)<\/td>/)
    {
      print $+{date} . "   " . $+{plz} . "   " . $+{status} . "\n";
    }
  }
}

close $FH;

