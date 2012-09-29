print "\n\n";

use Mail::Sendmail;

# Get the HTML of The Catlow's showtimes
my $curlResult = `curl -s http://thecatlow.com/html/showtimes.html`;

# Attempt to locate the movie currently playing
$curlResult =~ m/<h2><span class="descrpmovieTitle">(.*?)<\/span><\/h2>/;
my $moviePlaying = $1;

# Attempt to locate the poster URL for the movie currently playing
$curlResult =~ m/<div id="poster_feature"><img src="(.*?)".*?>/;
my $imageURL = $1;
# replace the ".." in the URL with "http://www.thecatlow.com" for the absolute filepath
$imageURL =~ s/\.\./http:\/\/www\.thecatlow\.com/;

# retrieve the list of email recipients
open RECIPIENTS_FILE, "recipients.txt" || print "Error: $!\n";

# Each line of the file represents an address
my @recipients = <RECIPIENTS_FILE>;
chomp @recipients;

# Make the mail message
my $htmlMailMessage = <<END_HTML;
<html>
<head><link href='http://fonts.googleapis.com/css?family=Amethysta' rel='stylesheet' type='text/css'></head>
<div style="display:block; width:400px; text-align:center; margin:auto; font-size:20px; color:#555; font-family:'Amethysta', Georgia, serif;">
<p><emph>Now Playing at The Catlow Theater...</emph></p>
</div>

<div style="display:block; width:400px; text-align:center; margin:auto; font-size:50px; color:#222; font-family:'Amethysta', Georgia, serif;">
<img src="$imageURL" /><br />
<p>$moviePlaying</p>
</div>
</html>
END_HTML

%mail = ( To      => join(", ",@recipients),
		From    => 'nowplaying@thecatlow.com',
		'content-type' => 'text/html; charset="iso-8859-1"',
		Subject => "Now Playing at The Catlow: $moviePlaying",
		Body => $htmlMailMessage
		);

$mail{body} = <<END_OF_BODY;
<html>$htmlMailMessage</html>
END_OF_BODY

sendmail(%mail) || print "Error: $Mail::Sendmail::error\n";

print "OK. Log says:\n", $Mail::Sendmail::log;

print "\n\n";