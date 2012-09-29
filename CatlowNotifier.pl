use FindBin;
open CATLOW_LOG, ">>$FindBin::Bin/log.txt" || print "Error: $!\n";
use POSIX qw(strftime);
my $nowString = strftime "%a %b %e %H:%M:%S %Y", localtime;
print CATLOW_LOG $nowString."\n\n";


use Mail::Sendmail;

# Get the HTML of The Catlow's showtimes
my $curlResult = `curl -s http://thecatlow.com/html/showtimes.html`;

# Attempt to locate the movie currently playing
$curlResult =~ m/<h2><span class="descrpmovieTitle">(.*?)<\/span><\/h2>/;
my $moviePlaying = $1;

# Check to see if we've already sent an email about this movie.
open EXPIRED_MOVIE_FILE, "$FindBin::Bin/previousMovie.txt" || print CATLOW_LOG "Error: $!\n";
my @expiredMovies = <EXPIRED_MOVIE_FILE>;
chomp @expiredMovies;
close EXPIRED_MOVIE_FILE;
if ($expiredMovies[0] eq $moviePlaying) {
	print CATLOW_LOG "Recipients have already been notified of $moviePlaying. No email sent.";
	print CATLOW_LOG "\n\n=========================\n\n";
	die;
}

# We have not sent an email about this movie, so we overwite the file with the current movie, and send an email
open EXPIRED_MOVIE_FILE, ">$FindBin::Bin/previousMovie.txt" || print CATLOW_LOG "Error: $!\n";
print EXPIRED_MOVIE_FILE $moviePlaying;
close EXPIRED_MOVIE_FILE;

# Attempt to locate the poster URL for the movie currently playing
$curlResult =~ m/<div id="poster_feature"><img src="(.*?)".*?>/;
my $imageURL = $1;
# replace the ".." in the URL with "http://www.thecatlow.com" for the absolute filepath
$imageURL =~ s/\.\./http:\/\/www\.thecatlow\.com/;

$curlResult =~ m/<p><span class="mainBoldRed">Synopsis:<\/span><br \/>(.*?)<\/p>/s;
my $movieSynopsis = $1;
$movieSynopsis =~ s/\s+/ /g;

# retrieve the list of email recipients
open RECIPIENTS_FILE, "$FindBin::Bin/recipients.txt" || print CATLOW_LOG "Error: $!\n";
# Each line of the file represents an address
my @recipients = <RECIPIENTS_FILE>;
chomp @recipients;
close RECIPIENTS_FILE;

# Make the mail message
my $htmlMailMessage = <<END_HTML;
<html>
<head><link href='http://fonts.googleapis.com/css?family=Amethysta' rel='stylesheet' type='text/css'></head>
<div style="display:block; width:400px; text-align:center; margin:auto; font-size:20px; color:#555; font-family:'Amethysta', Georgia, serif;">
<p><emph>Now Playing at The Catlow Theater...</emph></p>
</div>

<div style="display:block; width:400px; text-align:center; margin:auto; font-size:50px; color:#222; font-family:'Amethysta', Georgia, serif;">
<img src="$imageURL" /><br />
<p style="margin-top: 10px; margin-bottom:10px;">$moviePlaying</p>
<p style="text-align: left; font-size: 16px;">$movieSynopsis</p>
</div>

<p style="color:#888; margin-top: 30px;">This automated message is not affiliated with The Catlow theater in any way. If you would like to be taken off of this mailing list, please email: aapierce0\@gmail.com.</p>
</html>
END_HTML

%mail = (BCC    => join(", ",@recipients),
		From    => 'nowplaying@thecatlow.com',
		'content-type' => 'text/html; charset="iso-8859-1"',
		Subject => "Now Playing at The Catlow: $moviePlaying",
		Body => $htmlMailMessage
		);

$mail{body} = <<END_OF_BODY;
<html>$htmlMailMessage</html>
END_OF_BODY

sendmail(%mail) || print CATLOW_LOG "Error: $Mail::Sendmail::error\n";

print CATLOW_LOG "OK. Log says:\n", $Mail::Sendmail::log;
print CATLOW_LOG "\n\n=========================\n\n";
close CATLOW_LOG;