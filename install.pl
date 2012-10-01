#! /usr/bin/env perl

# install.pl
# script to create symlinks from the checkout of davesdots to the home directory

use strict;
use warnings;

use File::Path qw(mkpath rmtree);
use File::Glob ':glob';
use Cwd 'cwd';

my $scriptdir = cwd() . '/' . $0;
$scriptdir    =~ s{/ [^/]+ $}{}x;

my $home = bsd_glob('~', GLOB_TILDE);

if(grep /^(?:-h|--help|-\?)$/, @ARGV) {
	print <<EOH;
install.pl: installs symbolic links from dotfile repo into your home directory

Options:
	-f          force an overwrite existing files
	-h, -?      print this help

Destination directory is "$home".
Source files are in "$scriptdir".
EOH
	exit;
}

my $force = 0;
$force = 1 if grep /^(?:-f|--force)$/, @ARGV;

unless(eval {symlink('', ''); 1;}) {
	die "Your symbolic links are not very link-like.\n";
}

my %links = (
	screenrc   => '.screenrc',
	ackrc      => '.ackrc',
	toprc      => '.toprc',
	dir_colors => '.dir_colors',
	lessfilter => '.lessfilter',

	vim      => '.vim',
	vimrc    => '.vimrc',
	_vimrc   => '_vimrc',
	gvimrc   => '.gvimrc',

	man      => '.man',

	emacsrc => '.emacs',
	emacs => '.emacsdir',

	commonsh => '.commonsh',

	inputrc  => '.inputrc',

	bash          => '.bash',
	bashrc        => '.bashrc',
	bash_profile  => '.bash_profile',

	zsh      => '.zsh',
	zshrc    => '.zshrc',

	ksh      => '.ksh',
	kshrc    => '.kshrc',
	mkshrc   => '.mkshrc',

	shinit  => '.shinit',

	Xdefaults  => '.Xdefaults',
	Xresources => '.Xresources',

	'uncrustify.cfg' => '.uncrustify.cfg',
	'indent.pro'     => '.indent.pro',

	xmobarrc    => '.xmobarrc',
	'xmonad.hs' => '.xmonad/xmonad.hs',

	'Wombat.xccolortheme'  => 'Library/Application Support/Xcode/Color Themes/Wombat.xccolortheme',
#	'Wombat.dvtcolortheme' => 'Library/Developer/Xcode/UserData/FontAndColorThemes/Wombat.dvtcolortheme',

	gitconfig => '.gitconfig',
	gitignore => '.gitignore',

	tigrc     => '.tigrc',

	'acm/caffeinate' => 'bin/caffeinate',
	lock       => 'bin/lock',

	gdbinit => '.gdbinit',

	# z (https://github.com/rupa/z)
	'z/z.sh' => 'bin/z.sh',
	'z/z.1' => '.man/z.1',

	# git extras (https://github.com/visionmedia/git-extras)
	'git-extras/bin/git-alias' => 'bin/git-alias',
	'git-extras/bin/git-back' => 'bin/git-back',
	'git-extras/bin/git-bug' => 'bin/git-bug',
	'git-extras/bin/git-changelog' => 'bin/git-changelog',
	'git-extras/bin/git-commits-since' => 'bin/git-commits-since',
	'git-extras/bin/git-contrib' => 'bin/git-contrib',
	'git-extras/bin/git-count' => 'bin/git-count',
	'git-extras/bin/git-create-branch' => 'bin/git-create-branch',
	'git-extras/bin/git-delete-branch' => 'bin/git-delete-branch',
	'git-extras/bin/git-delete-merged-branches' => 'bin/git-delete-merged-branches',
	'git-extras/bin/git-delete-submodule' => 'bin/git-delete-submodule',
	'git-extras/bin/git-delete-tag' => 'bin/git-delete-tag',
	'git-extras/bin/git-effort' => 'bin/git-effort',
	'git-extras/bin/git-extras' => 'bin/git-extras',
	'git-extras/bin/git-feature' => 'bin/git-feature',
	'git-extras/bin/git-fresh-branch' => 'bin/git-fresh-branch',
	'git-extras/bin/git-gh-pages' => 'bin/git-gh-pages',
	'git-extras/bin/git-graft' => 'bin/git-graft',
	'git-extras/bin/git-ignore' => 'bin/git-ignore',
	'git-extras/bin/git-info' => 'bin/git-info',
	'git-extras/bin/git-local-commits' => 'bin/git-local-commits',
	'git-extras/bin/git-obliterate' => 'bin/git-obliterate',
	'git-extras/bin/git-pull-request' => 'bin/git-pull-request',
	'git-extras/bin/git-refactor' => 'bin/git-refactor',
	'git-extras/bin/git-release' => 'bin/git-release',
	'git-extras/bin/git-rename-tag' => 'bin/git-rename-tag',
	'git-extras/bin/git-repl' => 'bin/git-repl',
	'git-extras/bin/git-setup' => 'bin/git-setup',
	'git-extras/bin/git-show-tree' => 'bin/git-show-tree',
	'git-extras/bin/git-squash' => 'bin/git-squash',
	'git-extras/bin/git-summary' => 'bin/git-summary',
	'git-extras/bin/git-touch' => 'bin/git-touch',
	'git-extras/bin/git-undo' => 'bin/git-undo',
);

my $contained = (substr $scriptdir, 0, length($home)) eq $home;
my $prefix = undef;
if ($contained) {
	$prefix = substr $scriptdir, length($home);
	($prefix) = $prefix =~ m{^\/? (.+) [^/]+ $}x;
}

chomp(my $uname = `uname -s`);
`cc answerback.c -o answerback.$uname`;
if ($? != 0) {
	warn "Could not compile answerback.\n";
} else {
	$links{"answerback.$uname"} = "bin/answerback.$uname";
}


my $i = 0; # Keep track of how many links we added
for my $file (keys %links) {
	# See if this file resides in a directory, and create it if needed.
	my($path) = $links{$file} =~ m{^ (.+/)? [^/]+ $}x;
	mkpath("$home/$path") if $path;

	my $src  = "$scriptdir/$file";
	my $dest = "$home/$links{$file}";

	# If a link already exists, see if it points to this file. If so, skip it.
	# This prevents extra warnings caused by previous runs of install.pl.
	if(!$force && -e $dest && -l $dest) {
		next if readlink($dest) eq $src;
	}

	# Remove the destination if it exists and we were told to force an overwrite
	if($force && -d $dest) {
		rmtree($dest) || warn "Couldn't rmtree '$dest': $!\n";
	} elsif($force) {
		unlink($dest) || warn "Couldn't unlink '$dest': $!\n";
	}

	if ($contained) {
		chdir $home;
		$dest = "$links{$file}";
		$src = "$prefix$file";
		if ($path) {
			my $nesting = split(/\//, $dest) - 1;
			$src = "../"x $nesting . "$src";
		}
	}

	symlink($src => $dest) ? $i++ : warn "Couldn't link '$src' to '$dest': $!\n";
}

print "$i link";
print 's' if $i != 1;
print " created\n";
