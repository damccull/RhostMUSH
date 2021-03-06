#!/usr/bin/perl

# use strict;
my ($line, $counter, $junk, $numobjs, $type, $word,
      $cnt, $name, $bit1, $bit2, $temp, $tmp, $contents);
my (%user_attr, %user_attr_r, %tempdata);

my @type_flags;
my %penn_flags, %penn_types, %room_flags, %thing_flags,
   %exit_flags, %player_flags, %penn_locks, %penn_attr,
   %penn_db_flags;
my $next_attr = 257;

# Initialize hashes for attributes and flags.

# Database flags used by penn, I probably wont use all of these, but
# the script will list the set flags anyway.
#
# Changed this a little, now indicates whether or not a flag is:
#  1: required
#  0: doesnt matter
# -1: old db, will break.
%penn_db_flags = (
	0x01 => {'name' => 'DBF_NO_CHAT_SYSTEM', 'req' => 1},
	0x02 => {'name' => 'DBF_WARNINGS', 'req' => 0},
	0x04 => {'name' => 'DBF_CREATION_TIMES', 'req' => 0},
	0x08 => {'name' => 'DBF_NO_POWERS', 'req' => -1},
	0x10 => {'name' => 'DBF_NEW_LOCKS', 'req' => -1},
	0x20 => {'name' => 'DBF_NEW_STRINGS', 'req' => 1},
	0x40 => {'name' => 'DBF_TYPE_GARBAGE', 'req' => 1},
	0x80 => {'name' => 'DBF_SPLIT_IMMORTAL', 'req' => 1},
	0x100 => {'name' => 'DBF_NO_TEMPLE', 'req' => 1},
	0x200 => {'name' => 'DBF_LESS_GARBAGE', 'req' => -1},
	0x400 => {'name' => 'DBF_AF_VISUAL', 'req' => 1},
	0x800 => {'name' => 'DBF_VALUE_IS_COST', 'req' => 1},
	0x1000 => {'name' => 'DBF_LINK_ANYWHERE', 'req' => 1},
	0x2000 => {'name' => 'DBF_NO_STARTUP_FLAG', 'req' => 1},
	0x4000 => {'name' => 'DBF_PANIC', 'req' => -1},
	0x8000 => {'name' => 'DBF_AF_NODUMP', 'req' => 1},
	0x10000 => {'name' => 'DBF_SPIFFY_LOCKS', 'req' => 1}
	);

%penn_types = (
	0x0 => 0x0,	# TYPE_ROOM
	0x1 => 0x1,	# TYPE_THING
	0x2 => 0x2,	# TYPE_EXIT
	0x3 => 0x3,	# TYPE_PLAYER
	0x6 => 0x5,	# TYPE_GARBAGE
	0x7 => 0x7);	# NOTYPE

  # Type 0x0, Room.
%room_flags = (
	0x8 => {'flag' => 0x4, 'word' => 2}, # FLOATING
	0x10 => {'flag' => 0x2, 'word' => 2}, # ABODE
	0x20 => {'flag' => 0x80, 'word' => 1}, # JUMP_OK
	# 0x40 NO TEL, does it apply to rooms in rhost?
	0x80 => {'flag' => 0x1000, 'word' => 2}, # TEMPLE
	0x100 => {'flag' => 0x40, 'word' => 2} # LISTEN
	# 0x200 Z_TEL, 0x400 INHEARIT, 0x1000 UNINSPECTED
	);

# Type 0x1, Thing.
%thing_flags = (
	0x8 => {'flag' => 0x200, 'word' => 1}, # DESTROY_OK
	0x10 => {'flag' => 0x20000, 'word' => 1}, # PUPPET
	0x20 => {'flag' => 0x8000, 'word' => 1} # PENN: LISTEN, RHOST: MONITOR
#	0x40 NOLEAVE, 0x80 INHEARIT, 0x100 Z_TEL
	);

# Type 0x2, Exit.
# No applicable penn exit flags to convert to Rhost.

#Type 0x3, Player.
%player_flags = (
	# 0x8 PLAYER_TERSE, suppress autolook messages
	# Different from Rhost TERSE, Only show room name on look?
	0x10 => {'flag' => 0x10000, 'word' => 1}, # MYOPIC
	0x20 => {'flag' => 0x04000000, 'word' => 1}, # NOSPOOF
	0x40 => {'flag' => 0x10000000, 'word' => 2}, # SUSPECT

#	0x80 PLAYER_GAGGED, 0x100 PLAYER_MONITOR
	
	0x200 => {'flag' => 0x40000000, 'word' => 2}, # CONNECT
	0x400 => {'flag' => 0x02000000, 'word' => 2}, # PENN: ANSI, RHOST: ANSI

#	0x800 PLAYER_ZONE, 0x1000 PLAYER_JURY, 0x2000 PLAYER_JUDGE
#	0x4000 PLAYER_FIXED, 0x8000 PLAYER_UNREG, 0x10000 PLAYER_VACATION
	
	0x80000 => {'flag' => 0x04000000, 'word' => 2} # PENN: COLOR
						       # RHOST: ANSICOLOR
#	0x100000 PLAYER NOACCENTS, 0x200000 PLAYER_PARANOID
	);

@type_flags = (\%room_flags, \%thing_flags,
  		    0, \%player_flags);

# Penn flags, related to first word o\f rhost flags.
%penn_flags = (
	0x10 => {'flag' => 0x10, 'word' => 1}, # WIZARD
	0x20 => {'flag' => 0x20, 'word' => 1}, # LINK_OK
	0x40 => {'flag' => 0x40, 'word' => 1}, # DARK
	0x80 => {'flag' => 0x01000000, 'word' => 1}, # VERBOSE
	0x100 => {'flag' => 0x100, 'word' => 1}, # STICKY
	0x200 => {'flag' => 0x8, 'word' => 1},   # PENN: TRANSPARENT
	  					 # RHOST: SEETHRU
	0x400 => {'flag' => 0x400, 'word' => 1}, # HAVEN
	0x800 => {'flag' => 0x800, 'word' => 1}, # QUIET
	0x1000 => {'flag' => 0x1000, 'word' => 1}, # HALT
	0x2000 => {'flag' => 0x8, 'word' => 2},    # UNFINDABLE
	0x4000 => {'flag' => 0x4000, 'word' => 1}, # GOING
#	0x8000 OBSOLETE PENN FLAG, ACCESSED.
#	0x10000 PENN: MARKED, IGNORE.
#	0x20000 PENN: NOWARN
	0x40000 => {'flag' => 0x40000, 'word' => 1}, # CHOWN_OK
	0x80000 => {'flag' => 0x80000, 'word' => 1}, # ENTER_OK
	0x100000 => {'flag' => 0x100000, 'word' => 1}, # VISUAL
#	0x400000 ROYALTY, IGNORED FOR NOW
	0x200000 => {'flag' => 0x20, 'word' => 2}, # LIGHT
	0x800000 => {'flag' => 0x800000, 'word' => 1}, # OPAQUE
	0x1000000 => {'flag' => 0x2000000, 'word' => 1}, # INHERIT
	0x2000000 => {'flag' => 0x2000, 'word' => 1}, # PENN: DEBUGGING
	     						  # RHOST: TRACE
	0x4000000 => {'flag' => 0x10000000, 'word' => 1},	# SAFE
#	0x8000000 => {'flag' => 0x00400000, 'word' => 1},
	   					# STARTUP (OBSOLETE)
	    				        # RHOST: HAS_STARTUP
	0x10000000 => {'flag' => 0x40000000, 'word' => 1},
	  					# PENN: AUDIBLE, RHOST: HEARTHRU
	0x20000000 => {'flag' => 0x8000, 'word' => 3} # NO_COMMAND
#	0x40000000 PENN: GOING_TWICE
	);

%penn_locks = (
	Basic => '42',
	Enter => '59',
	Use => '62',
#	Zone
	Page => '61',
	Teleport => '65',
	Speech => '199',
#	Listen, Command
	Parent => '98',
	Link => '93',
	Leave => '60',
	Drop => '86',
	Give => '63',
	Mail => '157',
#	Follow, Examine, Chzone, Forward
	Control => '96');

%penn_attr = (
	OSUCCESS => '1',
	OFAILURE => '2',
	FAILURE => '3',
	SUCCESS => '4',
	XYXXY => '5',
	DESCRIBE => '6',
	SEX => '7',
	ODROP => '8',
	DROP => '9',
	ASUCCESS => '12',
	AFAILURE => '13',
	ADROP => '14',
	AUSE => '16',
	CHARGES => '17',
	RUNOUT => '18',
	STARTUP => '19',
	ACLONE => '20',
	APAYMENT => '21',
	OPAYMENT => '22',
	PAYMENT => '23',
	COST => '24',
	LISTEN => '26',
	AAHEAR => '27',
	AMHEAR => '28',
	AHEAR => '29',
	LAST => '30',
	IDESCRIBE => '32',
	ENTER => '33',
	OXENTER => '34',
	AENTER => '35',
	ADESCRIBE => '36',
	ODESCRIBE => '37',
	RQUOTA => '38',
	ACONNECT => '39',
	ADISCONNECT => '40',
#	LOCK => '42', NAME => '43'
	COMMENT => '44',
	USE => '45',
	OUSE => '46',
	SEMAPHORE => '47',
#	TIMEOUT => '48'
	QUOTA => '49',
	LEAVE => '50',
	OLEAVE => '51',
	ALEAVE => '52',
	OENTER => '53',
	OXLEAVE => '54',
	MOVE => '55',
	OMOVE => '56',
	AMOVE => '57',
	ALIAS => '58',
#	LENTER => '59', LLEAVE => '60', LPAGE => '61',
#	LUSE => '62', LGIVE => '63'
	EALIAS => '64',
	LALIAS => '65',
	EFAIL => '66',
	OEFAIL =>'67',
	AEFAIL => '68',
	LFAIL => '69',
	OLFAIL => '70',
	ALFAIL => '71',
#	REJECT => '72'
	AWAY => '73',
	IDLE => '74',
	UFAIL => '75',
	OUFAIL => '76',
	AUFAIL => '77',
# 	PFAIL => '78',
	TPORT => '79',
	OTPORT => '80',
	OXTPORT => '81',
	ATPORT => '82',
#	PRIVS => '83', LOGINDATA => '84', LTPORT => '85', LDROP => '86',
#	LRECEIVE => '87'
	LASTSITE => '88',
	INPREFIX => '89',
	PREFIX => '90',
	INFILTER => '91',
	FILTER => '92',
#	LLINK => '93', LTELOUT => '94'
	FORWARDLIST => '95',
#	LCONTROL => '96', LUSER => '97', LPARENT => '98'
	VA => '100', VB => '101', VC => '102', VD => '103', VE => '104',
	VF => '106', VG => '107', VH => '108', VI => '109', VJ => '110',
	VK => '111', VL => '112', VM => '113', VN => '114', VO => '115',
	VP => '116', VQ => '117', VR => '118', VS => '119', VT => '120',
	VU => '121', VV => '122', VW => '123', VX => '124', VY => '125',
	VZ => '127',
#	CHANNEL, AGUID, ZA-ZZ, LIFE
	REGISTERED_EMAIL => '156',
#	LMAIL, LSHARE, GFAIL, OGFAIL, AGFAIL, RFAIL, ORFAIL, ARFAIL, DFAIL
#	ODFAIL, ADFAIL, ATFAIL, TOFAIL, OTFAIL, AOTFAIL, ATOFAIL, AMPASS, AMPSET
	LASTPAGED => '177',
#	RETPAGE, RECTIME, MCURR, MQUOTA, LQUOTA, TQUOTA, MTIME, MSAVEMAX
#	MSAVECUR, IDENT, LZONEWIZ, LZONETO, LTWINK, SITEGOOD, SITEBAD
#		MAILSIG
	MAILSIGNATURE => '193',
#	ADESC2, PAYLIM, DESC2, RACE, CMDCHECK, LSPEECH, SFAIL, ASFAIL, AUTOREG
#	LDARK, STOUCH, SATOUCH, SOTOUCH, SLISTEN, SALISTE, SOLISTEN, STASTE
#	SATASTE, SOTASTE, SSMELL, SASMELL, SOSMELL, LDROPTO, LOPEN, LCHOWN,
#	CAPTION, ANSINAME, TOTCMDS, STCMDS, RECEIVELIM
	CONFORMAT => '224',
	EXITFORMAT => '225',
#	LDEXIT_FMT, MODIFY_TIME, CREATED_TIME, ALTNAME, LALTNAME, INVTYPE
#	TOTCHARIN, TOTCHAROUT, LGIVETO, LGETFROM, SAYSTRING, LASTCREATE
#	SAVESENDMAIL, PROGBUFFEr, PROGPROMPT, PROGPROMPTBUF, TEMPBUFFER,
#	DESTVATTRMAX, A_RLEVEL
	NAMEFORMAT => '245',
	LASTIP => '246'
#	VLIST, LIST, STRUCT, TEMP
		);

open(FHANDLE, $ARGV[0]) || die("Could not open specified file!");

# FIX ME!
$dbflags = &getline;
$dbflags =~ m/\+V\d+/;
$dbflags = substr $dbflags,2;

# Subtract 2, divide by 256. Who knows why they chose this.
$dbflags = (($dbflags - 2) / 256) - 5;

# Check database flags.
print "PennMUSH Database Flags:\n";
foreach(sort keys %penn_db_flags)
{
  if(($dbflags & $_) != 0)
  {
    if($dbflags{$_}{'req'} == -1)
    {
      printf "\n%-20s%s", $penn_db_flags{$_}{'name'}, ': no longer in 1.7.5';
    }
    else
    {
      printf "\n%-20s%s", $penn_db_flags{$_}{'name'}, ': okay';
    }
  }
  elsif($penn_db_flags{$_}{'req'} == 1)
  {
      printf "\n%-20s%s\n", $penn_db_flags{$_}{'name'}, ': required, not present.';
      die "Conversion failed! Unsupported PennMUSH flatfile version!\n";
  }
}
print "\n";

$numobjs = &getline;
$numobjs =~ m/~\d+/;
$numobjs = substr $numobjs,1;	# strip initial ~ character
$counter = 0;

# open fils for both players, and attributes. cat them at the end.
open(ATTRIBS, '>attribs.tmp');
open(OBJECTS, '>objects.tmp');
open(LOG, '>convertdb.log');

while(&getline)
{
  last if $_ eq "***END OF DUMP***";

  $tempdata{'dbref'} = $_; # dbref, leaving the initial ! in place.
  $tempdata{'name'} = &getline;
  $cnt = $tempdata{'name'} =~ tr/"//d;	# remove any occurances of " within the name
					# "<NAME>" will usually be the only
					# instances
  $tempdata{'location'} = &getline;
  $tempdata{'contents'} = &getline;
  $tempdata{'exits'} = &getline;
  $tempdata{'next'} = &getline;
  $tempdata{'parent'} = &getline;
  $junk = &getline;

  $tempdata{'lockcount'} = substr $junk,10,10;

  if($tempdata{'lockcount'} > 0)
  {
    for($counter = 1 ; $counter <= $tempdata{'lockcount'} ; $counter++)
    {
      # Locks in rhost are treated as normal attributes, simply add them
      # to the list.

      # Discard the beginning, locks are formatted: type "Basic" etc.
      $tmp = &getline;
      ($junk, $type) = split /\s+/, $tmp;
      $type =~ tr/"//d;

      if(not defined $penn_locks{$type})
      {
        printf LOG "Unrecognized lock type: %s\n", $type;
        $junk = &getline;
        $junk = &getline;  # disregard the rest of this lock.
        $junk = &getline;
      }
      else
      {
        $tempdata{"lock_$counter"}{'type'} = $penn_locks{$type};
        $tempdata{"lock_$counter"}{'creator'} = &getline;
        $tempdata{"lock_$counter"}{'flags'} = &getline;

        $tempdata{"lock_$counter"}{'key'} = &getline;
        $tempdata{"lock_$counter"}{'key'} = substr $tempdata{"lock_$counter"}{'key'},5,-2;
      }
    }
  }

  $tempdata{'owner'} = &getline;
  $tempdata{'zone'} = &getline;
  $tempdata{'pennies'} = &getline;
  $tempdata{'flags'} = &getline;
  $tempdata{'toggles'} = &getline;
  chomp $tempdata{'toggles'};
 
  $tempdata{'powers'} = &getline;

  if($dbflags & 0x02) # Has warnings, read and discard.
  {
    $junk = &getline;
  }

  if($dbflags & 0x04) # Has creation times.
  {
    $tempdata{'mtime'} = &getline;
    $tempdata{'ctime'} = &getline;
  }

  $tempdata{'flags1'} = 0;
  $tempdata{'flags2'} = 0;
  $tempdata{'flags3'} = 0;
  $tempdata{'flags4'} = 0;
  $tempdata{'link'} = "-1";

  # Translate type
  $tmp = $tempdata{'flags'} & 0x07;

  # Check if the thing isnt a room, or an exit. If this is the case,
  # fix the object home.
  if (($tmp != 0) && ($tmp != 2))
  {
    $tempdata{'link'} = $tempdata{'exits'};
    $tempdata{'exits'} = '-1';
  }

  $tempdata{'flags1'} |= $penn_types{$tmp};

  # First deal with any-type flags.
  foreach (sort keys %penn_flags)
  {
    if((0+$tempdata{'flags'} & 0+$_) != 0) # has this flag
    {
      $word = $penn_flags{$_}{'word'};
      $tempdata{"flags$word"} |= $penn_flags{$_}{'flag'};
    }
  }

  # Now check type specific flags, which are
  # stored on the toggles value for Penn.
  $tmp = ($tempdata{'flags1'} & 0x07);

  if ($type_flags[$tmp] != 0)
  {
    foreach(keys %{$type_flags[$tmp]})
    {
      if((0+$tempdata{'toggles'} & 0+$_) != 0)
      {
	$word = $type_flags[$tmp]{$_}{'word'};
        $tempdata{"flags$word"} |= $type_flags[$tmp]{$_}{'flag'};
      }
    }
  }
  print OBJECTS $tempdata{'dbref'}, "\n";
  print OBJECTS $tempdata{'name'}, "\n";
  print OBJECTS $tempdata{'location'}, "\n";
  print OBJECTS $tempdata{'contents'}, "\n";
  print OBJECTS $tempdata{'exits'}, "\n";
  print OBJECTS $tempdata{'link'}, "\n";
  print OBJECTS $tempdata{'next'}, "\n";
  print OBJECTS "\n";
  print OBJECTS $tempdata{'owner'}, "\n";
  print OBJECTS $tempdata{'parent'}, "\n";
  print OBJECTS $tempdata{'pennies'}, "\n";
  print OBJECTS $tempdata{'flags1'}, "\n";
  print OBJECTS $tempdata{'flags2'}, "\n";
  print OBJECTS $tempdata{'flags3'}, "\n";
  print OBJECTS $tempdata{'flags4'}, "\n";
  print OBJECTS "0\n0\n0\n0\n0\n0\n0\n0\n";
  print OBJECTS "-1\n";

  # Write the attributes, beginning with locks.
  for($temp = 1; $temp <= $tempdata{'lockcount'}; $temp++)
  {
    print OBJECTS ">", $tempdata{"lock_$temp"}{'type'}, "\n";
    print OBJECTS $tempdata{"lock_$temp"}{'key'}, "\n";
  }
  # Next a couple of locks that I had to do seperately, because I was too
  # lazy to come up with a neater method.
  # Creation times.
  
  if(defined $tempdata{'ctime'})
  {
    print OBJECTS ">227\n", $tempdata{'mtime'}, "\n";
    print OBJECTS ">228\n", $tempdata{'ctime'}, "\n";
  }

  # Now read all of the attributes
  $counter = 0;

  $junk = &getline;

  while(1)
  {
    last if $junk eq "<";

    ($name, $bit1, $bit2) = split /\^/, $junk, 3;
    $name = substr $name,1;

    chomp $name;
    if(length($name) > 31)
    {
      $tmp = 1;
      
      $junk = substr $name, 0, 30-length($tmp); # new name
    
      $junk .= "~$tmp";
      while(defined($user_attr{$junk}))
      {
        $tmp++;
	$junk = substr $name, 0, 30-length($tmp);
	$junk .= "~$tmp";
      }
      print LOG "Truncated attribute '$name' on object '$tempdata{'dbref'}' to $junk\n\n";
      $name = $junk;
    }
    
    # lines can contain line feeds, so check each line until
    # we have the whole contents

    $junk = &getline;
    chomp $junk;
    while (((substr $junk,0,1) ne ']') and ($junk ne '<'))
    {
      $contents .= $junk;
      $junk = &getline;
      chomp $junk;
    }
    $contents = substr $contents,1,-1; # remove "'s from around penn
                                                          # attr contents

    if(defined $penn_attr{$name})
    {
      print OBJECTS ">$penn_attr{$name}\n";
      
      if(length($contents) >= 4000)
      {
        print LOG "Contents of attribute:\n$name\non object $tempdata{'dbref'} was larger than 4k.\n";
	$contents = substr $contents,0,3995;
      }
      else
      {
        print OBJECTS "$contents\n";
      }
    }
    else
    {
      if (not(defined $user_attr{$name}))
      {
        # GDBM doesnt handle multiples of 128  
	$next_attr++ if(($next_attr % 128) == 0);
        
        $user_attr{$name} = $next_attr;
        $user_attr_r{$next_attr} = $name;
        $next_attr++;
      }
      print OBJECTS ">$user_attr{$name}\n";
      print OBJECTS "$contents\n";
    }
  $contents = '';
  }
  print OBJECTS "<\n";
}

# print the header for the file
$next_attr++ if(($next_attr % 128) == 0);

print ATTRIBS "+V74247\n"; # Default Rhost flatfile dump flags.
print ATTRIBS "+S$numobjs\n";
print ATTRIBS "+N", $next_attr, "\n";

# Now write out any user created attributes.
for($temp = 257; $temp < $next_attr; $temp++)
{
  next if(($temp % 128) == 0);
  print ATTRIBS "+A$temp\n";
  print ATTRIBS "1:$user_attr_r{$temp}\n";
}
print OBJECTS "***END OF DUMP***\n";

close FHANDLE;
close ATTRIBS;
close OBJECTS;

sub getline
{
  $_ = <FHANDLE>;
  chomp;
  return $_;
}
