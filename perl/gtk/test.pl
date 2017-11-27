#!/usr/bin/perl -w
#helloworld.pl---Test the gtk2-perl whether works use Gtk2'-init'
use Glib qw(TRUE FALSE);
use Encode qw(decode);
use Gtk2 -init;
use Data::Dumper;
my $window=Gtk2::Window->new('toplevel');
print STDOUT Dumper($window);
$window->set_title('Hello World ');
$window->set_position('center_always');
$window->set_size_request(300,200);
$window->signal_connect('delete_event'=>sub{Gtk2->main_quit});
#my $label=Gtk2::Label->new(decode('utf8','你好'));
#$window->add($label);
#my $wg = Gtk2::Wadget->new('o');
my $b = Gtk2::CheckButton->new('Something');
$b->set_active(1);
#$b->show;
$window->add ($b);
$window->show_all();
Gtk2->main;

