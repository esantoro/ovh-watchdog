#!/usr/bin/env perl

use strict ;
use warnings ;
use diagnostics ;

binmode STDOUT, ':utf8';

use feature 'say';

use WWW::Mechanize ;
use HTML::Tree ;
use HTML::TreeBuilder ;

use Digest::MD5 qw(md5_base64) ;




{
  package Watchdog::Page ;

  use WWW::Mechanize ;
  use Digest::MD5 qw(md5_base64) ;
  use feature 'say' ;

  use Moose ;

  has 'robot' => (is => "ro",
		 isa => "WWW::Mechanize",
		 init_arg => undef,
		 default => sub { WWW::Mechanize->new(agent => "ESantoro's watchdog")} ) ;

  has 'url' => (isa =>"Str",
	       is => "rw",
	       required => 1) ;

  has 'title' => (isa => "Str",
		 is => "rw") ;

  has 'description' => (is => "rw",
			isa => "Str") ;

  has 'last_content' => (is => "rw",
			 isa => "Str",
			 default => "") ;
  has 'last_md5' => (is => 'rw',
		     isa => "Str",
		     default => "") ;

  # bisogna poter specificare un parametro che è un ref ad una subroutine da eseguire
  # quando viene trovato un cambiamento

  has change_detected => (is => "rw",
			  isa => "CodeRef") ;

  has change_detected_params => (is => "rw",
				 isa => "Ref",
				 default => undef) ;

  sub update {

    my $self = shift ;

    ## $no_action: if set to something that evaluates as non-unde
    ## it will trigger no action
    my $no_action = shift || 0 ;

    my $robot = $self->{robot} ;


    ## Looking for content of a particular element of the page:
    #
    # my $response = $robot->get("https://www.ovh.it/server_dedicati/kimsufi_2g.xml") ;
    # my $tree = HTML::TreeBuilder->new_from_content($response->decoded_content) ;
    # $tree->elementify() ;
    # my $element = $tree->look_down("_tag", "div",
    #			 "id", "showAvailability") ;

    my $response = $robot->get($self->url) ;
    my $new_html = $response->decoded_content ;
    my $new_md5 = md5_base64(Encode::encode_utf8 $new_html);

    if ($new_md5 ne $self->last_md5) {
      $self->last_md5($new_md5) ;
      $self->last_content($new_html) ;

      &{$self->change_detected}($self, $self->change_detected_params) unless $no_action ;
     }
  }
}


{
  package Watchdog::ThreadPool ;

  use threads ;

  use Moose ;

  has 'thread_pool' => (is => "rw",
			isa => "ArrayRef",
			init_arg => undef) ;

  sub watch_page {
    my ($page, $interval) = @_ ;
    $interval = $interval || 5 ;
    $page->update(1) ;
    while (1) {
      say "Updating page '". $page->title. "' (" . gmtime . ")" ;
      $page->update ;
      sleep $interval ;
    }
  }

  sub add {
    my ($self, $page, $interval) = @_ ;

    my $new_thread = threads->create(\&watch_page, $page, $interval) ;

    push @{ $self->{thread_pool}}, $new_thread ;
  }
}


sub notify_sms {
  my ($page, $params) = @_ ;
  say "Something changed in page '" . $page->title . "'" ;

  foreach my $number ( @{$params}) {
    my $command = "skype-sms-shooter --body='something changed in page \"".$page->title."\"' --recipient='$number'" ;
    say "Executing: " ;
    my $output = `$command` ;
    say $command ;
  }
}

use Data::Dumper ;

sub notify_dumb {
  my ($page, $params) = @_ ;
  say "Something happened in page " . $page->title ;
  say "Params: " ;
  foreach my $element (@{$params}) {
    say "-> " . $element ;
  }
  say Dumper $params ;
  say "End" ;
}

my $wd = Watchdog::ThreadPool->new() ;

my $page = Watchdog::Page->new(url => "http://127.0.0.1/~manu/text.txt",
			       title => "Sample test page",
			       change_detected => \&notify_sms,
			       change_detected_params => ["+39329xxxxxxx", "+39320xxxxxx"]) ;

my $pag_kimsufi = Watchdog::Page->new(url => "http://www.ovh.it/server_dedicati/index.xml",
					 title => "Kimsufi",
					 change_detected => \&notify_sms,
					 change_detected_params => ["+39329xxxxxxx", "+39320xxxxxx"]) ;

my $pag_k4g = Watchdog::Page->new(url => "http://www.ovh.it/server_dedicati/kimsufi_4g.xml",
					   title => "Kimsufi 4g",
					   change_detected => \&notify_sms,
					   change_detected_params => ["+39329xxxxxxx", "+39320xxxxxx"]) ;

my $pag_k2g = Watchdog::Page->new(url => "http://www.ovh.it/server_dedicati/kimsufi_2g.xml",
					   title => "Kimsufi 2g",
					   change_detected => \&notify_sms,
					   change_detected_params => ["+39329xxxxxxx", "+39320xxxxxx"]) ;

my $pag_k24g = Watchdog::Page->new(url => "http://www.ovh.it/server_dedicati/kimsufi_24g.xml",
					    title => "Kimsufi 24g",
					    change_detected => \&notify_sms,
					    change_detected_params => ["+39329xxxxxxx", "+39320xxxxxx"]) ;


$wd->add($pag_kimsufi, 300) ;
$wd->add($pag_k2g, 150) ;
$wd->add($pag_k4g, 60) ;
$wd->add($pag_k24g, 300) ;

#$wd->add($page) ;

while (1) {
  sleep 60 ;
}
