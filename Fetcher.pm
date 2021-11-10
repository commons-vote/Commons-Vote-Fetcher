package Commons::Vote::Fetcher;

use strict;
use warnings;

use Class::Utils qw(set_params);
use DateTime::Format::Strptime;
use MediaWiki::API;

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# MediaWiki api.
	$self->{'mw_api'} = 'https://commons.wikimedia.org/w/api.php';

	# Process parameters.
	set_params($self, @params);

	$self->{'_mw'} = MediaWiki::API->new;
	$self->{'_mw'}->{'config'}->{'api_url'} = $self->{'mw_api'};

	$self->{'_dt_parser'} = DateTime::Format::Strptime->new(
		pattern => '%FT%T',
		time_zone => 'UTC',
	);

	return $self;
}

sub date_of_first_upload {
	my ($self, $user) = @_;

	# Query for first uploaded image.
	my $ref = $self->{'_mw'}->api({
		action => 'query',
		list => 'allimages',
		aisort => 'timestamp',
		aiuser => $user,
		ailimit => 1,
	});

	# No images.
	if (! @{$ref->{'query'}->{'allimages'}}) {
		return;
	}

	# Timestamp of first uploaded image.
	my $mw_timestamp = $ref->{'query'}->{'allimages'}->[0]->{'timestamp'};

	# Return DateTime object.
	return $self->{'_dt_parser'}->parse_datetime($mw_timestamp);
}

sub images_in_category {
	my ($self, $category) = @_;

	my $images_ar = $self->{'_mw'}->list({
                action => 'query',
                list => 'categorymembers',
                cmtitle => 'Category:'.$category,
                cmtype => 'file',
                cmlimit => '10',
        });

	return @{$images_ar};
}

1;

__END__
