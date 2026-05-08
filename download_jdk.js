const https = require('https');
const fs = require('fs');

const url = "https://corretto.aws/downloads/latest/amazon-corretto-21-x64-windows-jdk.zip";
const dest = "D:\\jdk21.zip";

console.log("Downloading JDK 21...");

const file = fs.createWriteStream(dest);

https.get(url, (response) => {
    if (response.statusCode === 302 || response.statusCode === 301) {
        let redirectUrl = response.headers.location;
        if (redirectUrl.startsWith('/')) {
            redirectUrl = 'https://corretto.aws' + redirectUrl;
        }
        https.get(redirectUrl, handleResponse).on('error', handleError);
    } else {
        handleResponse(response);
    }
}).on('error', handleError);

function handleResponse(response) {
    if (response.statusCode !== 200) {
        console.error("Failed to download, status code: " + response.statusCode);
        process.exit(1);
    }
    
    const totalBytes = parseInt(response.headers['content-length'], 10);
    let downloadedBytes = 0;
    
    response.on('data', (chunk) => {
        downloadedBytes += chunk.length;
        if(totalBytes) {
            const percent = ((downloadedBytes / totalBytes) * 100).toFixed(1);
            process.stdout.write(`\rProgress: ${percent}%`);
        }
    });
    
    response.pipe(file);
    
    file.on('finish', () => {
        file.close();
        console.log("\nDownload complete!");
        process.exit(0);
    });
}

function handleError(err) {
    fs.unlink(dest, () => {});
    console.error("Error: " + err.message);
    process.exit(1);
}
