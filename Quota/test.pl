#!../../../perl
#!/local/perl-5.004/bin/perl

use blib;
use Quota;

print "Enter path to get quota for (NFS possible; default '.'): ";
chop($path = <STDIN>);
$path = "." unless $path =~ /\S/;
$dev = Quota::getqcarg($path) || die "$path: $!\n";
print "Using device/argument \"$dev\"\n";

##
##  Check if quotas present on this filesystem
##

if($dev =~ m#^[^/]+:#) {
  print "Is a remote file system\n";
}
elsif(Quota::sync($dev) && ($! != 1)) {  # ignore EPERM
  warn "Quota::sync: ".Quota::strerr."\n";
  die "Choose another file system - quotas not functional on this one\n";
}
else {
  print "Quotas are present on this filesystem (sync ok)\n";
}

##
##  call with one argument (uid defaults to getuid()
##

print "\nQuery this fs with default uid (which is real uid) $>\n";
($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::query($dev);
if(defined($bc)) {
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
  $bt = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $bt;
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
  $ft = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $ft;

  print "Your usage and limits are $bc ($bs/$bh/$bt) $fc ($fs/$fh/$ft)\n\n";
}
else {
  warn "Quota::query: ",Quota::strerr,"\n\n";
}

##
##  call with two arguments
##

{
  print "Enter a uid to get quota for: ";
  chop($uid = <STDIN>);
  unless($uid =~ /^\d{1,5}$/) {
    print "You have to enter a numerical uid in range 0..65535 here.\n";
    redo;
  }
}

($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::query($dev, $uid);
if(defined($bc)) {
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
  $bt = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $bt;
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
  $ft = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $ft;

  print "Usage and limits for $uid are $bc ($bs/$bh/$bt) $fc ($fs/$fh/$ft)\n\n";
}
else {
  warn Quota::strerr,"\n\n";
}

##
##  get quotas via RPC
##

if($dev =~ m#^/#) {
  print "Query localhost via RPC.\n";

  ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::rpcquery('localhost', $path);
  if(defined($bc)) {
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
    $bt = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $bt;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
    $ft = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $ft;

    print "Your Usage and limits are $bc ($bs/$bh/$bt) $fc ($fs/$fh/$ft)\n\n";
  }
  else {
    warn Quota::strerr,"\n\n";
  }
  print "Query localhost via RPC for $uid.\n";

  ($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::rpcquery('localhost', $path, $uid);
  if(defined($bc)) {
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($bt);
    $bt = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $bt;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ft);
    $ft = sprintf("%d:%d %d/%d/%d", $hour,$min,$mon,$mday,$year) if $ft;

    print "Usage and limits for $uid are $bc ($bs/$bh/$bt) $fc ($fs/$fh/$ft)\n\n";
  }
  else {
    warn Quota::strerr,"\n\n";
  }

}
else {
  print "Skipping RPC query test - already done above.\n\n";
}

##
##  set quota block & file limits for user
##

print "Enter path to set quota (empty to skip): ";
chop($path = <STDIN>);

if($path =~ /\S/) {
  print "New quota limits bs,bh,fs,fh for $uid (empty to abort): ";
  chop($in = <STDIN>);
  if($in =~ /\S/) {
    $dev = Quota::getqcarg($path) || die "$path: $!\n";
    unless(Quota::setqlim($dev, $uid, split(/\s*,\s*/, $in), 1)) {
      print "Quota set for $uid\n";
    }
    else {
      warn Quota::strerr,"\n";
    }
  }
}

##
##  Force immediate update on disk
##

if($dev !~ m#^[^/]+:#) {
  Quota::sync($dev) && ($! != 1) && die "Quota::sync: ".Quota::strerr."\n";
}
