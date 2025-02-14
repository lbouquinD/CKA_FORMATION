

const express = require('express');
const fs = require('fs');

const app = express();
const port = 3000;

app.get('/healthz', (req, res) => {
  res.sendStatus(200);
});

app.get('/readyz', (req, res) => {
  fs.writeFile('/tmp/ready', '', (err) => {
    if (err) throw err;
    console.log('Ready file created');
    res.sendStatus(200);
  });
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});