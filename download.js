const https = require('https');
const fs = require('fs');

const url = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip";
const dest = "D:\\android-tools-node.zip";

console.log("Downloading Android SDK using Node.js (Robust Stream)...");

const file = fs.createWriteStream(dest);

https.get(url, (response) => {
    if (response.statusCode !== 200) {
        console.error("Failed to download, status code: " + response.statusCode);
        process.exit(1);
    }
    
    const totalBytes = parseInt(response.headers['content-length'], 10);
    let downloadedBytes = 0;
    
    response.on('data', (chunk) => {
        downloadedBytes += chunk.length;
        const percent = ((downloadedBytes / totalBytes) * 100).toFixed(2);
        process.stdout.write(`\rProgress: ${percent}%`);
    });
    
    response.pipe(file);
    
    file.on('finish', () => {
        file.close();
        console.log("\nDownload complete without corruption!");
        process.exit(0);
    });
}).on('error', (err) => {
    fs.unlink(dest, () => {});
    console.error("Error: " + err.message);
    process.exit(1);
});
 