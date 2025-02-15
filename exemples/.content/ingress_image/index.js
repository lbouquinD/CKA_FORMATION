const express = require('express');
const app = express();
const port = 80;

app.get('/*', (req, res) => {
  const podName = process.env.POD_NAME || "Non défini";
  const urlPath = req.path;
  const referrerUrl = req.headers.referer || "Non défini";

  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <title>Infos Pod et URL</title>
    </head>
    <body>
      <h1>Informations du Pod</h1>
      <p><b>Nom du Pod:</b> <span id="pod-name">${podName}</span></p>
      <p><b>Path URL:</b> <span id="url-path">${urlPath}</span></p>
      <p><b>URL Appelante:</b> <span id="referrer-url">${referrerUrl}</span></p>
      <p><b>URL Actuelle:</b> <span id="current-url"></span></p>

      <script>
        const currentUrl = window.location.href;
        document.getElementById("current-url").textContent = currentUrl;
      </script>
    </body>
    </html>
  `;

  res.send(html);
});

app.listen(port, () => {
  console.log(`Serveur Node.js écoutant sur le port ${port}`);
});
