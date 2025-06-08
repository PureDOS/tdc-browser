#!/usr/bin/perl

#--------------------------------------------#
# tdc-browser                                #
# License: Public Domain (www.unlicense.org) #
#--------------------------------------------#

use utf8;
use strict;
use Encode;
use Archive::Zip;
use LWP::UserAgent;

my $zipdir = undef; # download needed files
#my $zipdir = "./"; # load files from directory

my $outdir = "out";
my $template = "index.html";

my $tdc_last_release = 22;

my ($tdc_release_url_prefix, $tdc_release_url_suffix) = ("http://www.totaldoscollection.org/nugnugnug/TDC_DAT_release_", ".zip");

my %validtags =
(
	"!" => 1, "Action" => 1, "Addon" => 1, "Adult" => 1, "Adventure" => 1, "Board" => 1, "Cards" => 1, "Chess" => 1, "Compilation" => 1, "Educational" => 1, "Golf" => 1, "Interactive Fiction" => 1, "Overlord" => 1, "Prologue" => 1, "Puzzle" => 1, "Racing" => 1, "Racing - Driving" => 1, "Role Playing (RPG)" => 1, "Role-Playing (RPG)" => 1, "Role-playing (RPG)" => 1, "Simulation" => 1, "Sports" => 1, "Strategy" => 1, "TAC" => 1, "TC" => 1, "TD0" => 1, "Tennis" => 1, "Trivia" => 1, "War" => 1,
	"a1" => 1, "a2" => 1, "a3" => 1, "a4" => 1, "a5" => 1, "a6" => 1, "a7" => 1, "a8" => 1, "a9" => 1, "alt" => 1, "b1" => 1, "b2" => 1, "b3" => 1, "b4" => 1, "b5" => 1, "b6" => 1, "b7" => 1, "b8" => 1, "cp" => 1, "cr" => 1, "f1" => 1, "f2" => 1, "h1" => 1, "h2" => 1, "h3" => 1, "h4" => 1, "h5" => 1, "h6" => 1, "h7" => 1, "o1" => 1, "o2" => 1, "o3" => 1,
	"tr Ar" => 1, "tr Cs" => 1, "tr De" => 1, "tr En" => 1, "tr Es" => 1, "tr Fi" => 1, "tr Fr" => 1, "tr He" => 1, "tr It" => 1, "tr Ko" => 1, "tr No" => 1, "tr Pt" => 1, "tr Ru" => 1, "tr Tr" => 1, "tr Zh" => 1, "tr-Ru" => 1,
	"SW" => 1, "SWR" => 1, "DC" => 1, "FW" => 1, "Fw" => 1,
	"CCD" => 1, "ccd" => 1, "ISO" => 1, "bin-cue" => 1, "NRG" => 1, "mdf" => 1, "IMA" => 1, "IMD" => 1, "tc" => 1, "JRC" => 1, "cr" => 1,
	"1.440k" => 1, "1.44M" => 1, "1200" => 1, "1200k" => 1, "1200k-1440k" => 1, "1200k-360k" => 1, "1220k" => 1, "1220k-360k" => 1, "1220kb" => 1, "1440K" => 1, "1440k" => 1, "1440k-720k" => 1, "160" => 1, "160k" => 1, "180k" => 1, "180k-360k" => 1, "320k" => 1, "360" => 1, "360K" => 1, "360k" => 1, "360k-1200k" => 1, "360k-720k" => 1, "720" => 1, "720K" => 1, "720k" => 1, "720k-1200k" => 1, "720k-1220k" => 1, "720k-1440k" => 1,
);

print "Loading Release ZIPs ...\n";
my (%gamedb, %tagsdb);
for (my $tdc = 5; $tdc <= $tdc_last_release; $tdc++)
{
	my $dh;
	if ($zipdir)
	{
		print("    Opening '"."TDC_DAT_release_".$tdc.".zip"." ...\n");
		open($dh, "<", $zipdir."TDC_DAT_release_".$tdc.".zip") or die "Failed to open file\n";
	}
	else
	{
		print("    Downloading '".$tdc_release_url_prefix.$tdc.$tdc_release_url_suffix."' ...\n");
		my $zipdata = GetUA($tdc_release_url_prefix.$tdc.$tdc_release_url_suffix);
		print "        ZIP file length: ".length($zipdata)."\n";
		open($dh, "+<", \$zipdata) or die;
	}
	binmode($dh);
	my $zip = Archive::Zip->new;
	$zip->readFromFileHandle($dh);
	foreach my $zipmembername ($zip->memberNames())
	{
		print "        File: $zipmembername - Decompressing...\n";
		unless ($zipmembername =~ /\.dat$/i) { die "Unknown file in ZIP [$zipmembername]\n"; }
		my $dat = decode('utf8', $zip->contents($zipmembername));
		print "        Decompressed - Parsing ...\n";
		$dat =~ s/\r//g;
		my $ingame = 0;
		my @filearr;
		while ($dat =~ /.*?\n/g)
		{
			my $ln = $&;
			if ($ingame)
			{
				if ($ln =~ /^\tname "(?:\\\d+\\|)(.+?).(?:zip|ZIP|7z|7Z)"\n$/)
				{
					if ($ingame ne "(") { die "Double game [$ingame] [$1]\n"; }
					$ingame = $1;
					if ($ingame =~ /\"/) { die "Double quote in name [$ingame]\n"; }
					if ($ingame =~ /\(Installer\)/) { $ingame = 0; next; }
					my $gameyear = (($ingame =~ /\((\d+x* ?)\)/)[0]);
					#if (!$gameyear) { print "    No year in [$ingame]\n"; }
					if (!$gameyear) { $ingame = 0; next; }
					my ($invalid_tag);
					while ($ingame =~ /\[([^\[\]]+)\]/g)
					{
						my $tags = $1;
						while ($tags =~ /\s*([^,]+)\s*/g)
						{
							if (!$validtags{$1}) { $invalid_tag++; }
							#if (!$tagsdb{$1}) { $tagsdb{$1} = 1; print "    \"$1\" => 1,\n"; }
						}
					}
					if ($invalid_tag) { $ingame = 0; next; }
					@filearr = ();
				}
				elsif ($ln =~ /^\tfile \( name (.+?) size (\S+) date (\d+)[\/\\](\d+)[\/\\](\d+) (\d+):(\d+)(?::(\d+)|) crc (\w+) \)\n$/)
				{
					my ($fname, $fsize, $fyear,$fmon,$fday,$fhour,$fmin,$fsec, $fcrc) = ($1, $2, $3, $4, $5, $6, $7, $8, $9);
					if (index($fname, '"') >= 0) { $fname =~ s/\"/\\\"/g; } #{ die "Double quote in file name [$&]\n"; }
					if (int($fyear) < 1900) { die "Unknown year in [$&]\n"; }
					$fname =~ s/\\/\//g;
					push(@filearr, "[\"".uc($fname)."\",".int($fsize).",".int($fyear-1900).",".int($fmon).",".int($fday).",".int($fhour).",".int($fmin).",".int($fsec).",\"".lc($fcrc)."\"]");
				}
				elsif ($ln eq ")\n")
				{
					if ($ingame eq "(") { die "    Missing game name [$ingame]\n"; }
					if (!@filearr) { die "    No file in [$ingame]\n"; }
					$gamedb{$ingame}->{$tdc} = join(",", sort @filearr);
					$ingame = 0;
				}
				else { die "Unknown game line [$ln]\n"; }
			}
			elsif ($ln eq "game (\n")
			{
				$ingame = "(";
			}
			elsif ($ln =~ /\bDOSCenter \(\n/) {}
			elsif ($ln =~ /\b(Name|Description|Version|Date|Author|Homepage|Comment):/) {}
			elsif ($ln eq ")\n") {}
			elsif ($ln eq "\n") {}
			elsif ($ln =~ /^\tfile \( name (.+?) size (\S+) date (\d+)[\/\\](\d+)[\/\\](\d+) (\d+):(\d+)(?::(\d+)|) crc (\w+) \)\n$/) {}
			else { die "Unknown root line [$ln]"; }
		}
	}
	close($dh);
}
print "Done!\n\n";

if (!mkdir($outdir))
{
	opendir(DIR, $outdir);
	my @files = readdir(DIR);
	closedir(DIR);
	foreach my $f (@files) { if (substr($f, 0, 1) ne ".") { unlink($outdir."/".$f); } }
}

print "Building JS data set into '$outdir'...\n";
my $ranges;
my @gamedb_names = sort { "\L$a" cmp "\L$b" } keys %gamedb;
for (my ($i, $ilast, $outlen, $prevgame, $lastsplit, $nextrange, @out) = (0, @gamedb_names-1, 0, "", 0, 0); $i <= $ilast; $i++)
{
	my $ingame = $gamedb_names[$i];
	if (uc(substr($ingame, 0, 4)) ne uc(substr($prevgame, 0, 4)))
	{
		$lastsplit = @out;
	}
	$prevgame = $ingame;

	my %filesets;
	foreach my $tdc (reverse sort { $a <=> $b } keys %{$gamedb{$ingame}})
	{
		my $filearr = $gamedb{$ingame}->{$tdc};
		$filesets{$filearr} .= $tdc.",";
	}

	my %tdcsets = reverse %filesets;
	foreach my $tdcset (reverse sort { $a <=> $b } keys %tdcsets)
	{
		my $line = "[\"$ingame\",[".join(",", sort { $a <=> $b } grep { length > 0 } split(",", $tdcset))."],[".$tdcsets{$tdcset}."]],\n";
		push(@out, $line);
		$outlen += length($line);
	}

	my $isend = ($i == $ilast);
	if (($outlen > 512*1024 && $lastsplit) || $isend)
	{
		my @block = splice(@out, 0, ($isend ? int(@out) : $lastsplit));
		print "    Writing "."tdc_".$nextrange.".js"."\n";
		open(OUT, ">:raw:encoding(utf-8)", $outdir."/"."tdc_".$nextrange.".js");
		print OUT "document.OnTDCData([\n";
		print OUT join("", @block);
		print OUT "]);";

		$ranges .= $nextrange.($isend ? "" : ",");
		$nextrange = unpack("N", uc(encode("utf-8", substr($block[-1], 2, 4)))."\0\0\0\0") + 1;
		$lastsplit = 0;
		$outlen = length(join("", @out));
	}
}
print "Done!\n\n";

print "Building index.html from $template ...\n";
open(IN, "<:raw:encoding(utf-8)", $template);
open(OUT, ">:raw:encoding(utf-8)", $outdir."/index.html");
while (<IN>)
{
	my $line = $_;
	$line =~ s/<<<RANGES>>>/$ranges/;
	print OUT $line;
}
close(OUT);
close(IN);
print "Done!\n\n";

sub GetUA
{
	my $ua = LWP::UserAgent->new(send_te => 0, ssl_opts => { verify_hostname => 0 }, protocols_allowed => ['http','https'],);
	my $req = HTTP::Request->new('GET', $_[0]);
	my $res = $ua->request($req);
	return $res->decoded_content;
}
