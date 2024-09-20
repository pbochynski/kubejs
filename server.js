const express = require('express');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const axios = require('axios');
const stream = require('stream');
const FormData = require('form-data');
const app = express();
const port = 3000;

console.log("Starting server...");
const target = process.env.TARGET || 'localhost';
console.log(`Target: ${target}`); 
const upload = multer({ dest: 'uploads/' });

app.set('serverTimeout', 30000);
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.post('/upload', upload.single('file'), (req, res) => {
  const tempPath = req.file.path;
  const targetPath = path.join(__dirname, 'uploads', `${uuidv4()}.txt`);

  fs.rename(tempPath, targetPath, err => {
    if (err) return res.sendStatus(500);
    res.json({ resourceId: path.basename(targetPath) });
  });
});

app.get('/files/:id', (req, res) => {
  const filePath = path.join(__dirname, 'uploads', req.params.id);

  fs.readFile(filePath, 'utf8', (err, data) => {
    if (err) return res.sendStatus(404);
    res.send(data);
  });
});

app.get('/test', async (req, res) => {
  // get number of lines from request query param
  const numLines = req.query.lines || 72; 
  console.log(`Generating ${numLines} lines`);
  const form = new FormData();
  const passThrough = new stream.PassThrough();

  form.append('file', passThrough, {
    filename: `${uuidv4()}.txt`,
    contentType: 'text/plain'
  });
  axios.post(`http://${target}:3000/upload`, form, {
    headers: form.getHeaders()
  })
  .then(response => {
    console.log('File uploaded successfully', response.data);
    res.json({ resourceId: response.data.resourceId });
  })
  .catch(error => {
    console.error(error); 
    res.status(500).send('Error uploading file');
  });
  for (let i=0; i<numLines; i++) {
    console.log(`Sending line ${i+1} of ${numLines}`);
    passThrough.write(`Sending line ${i+1} of ${numLines}`);
    await new Promise(resolve => setTimeout(resolve, 5000)); // 5 seconds delay
  }
  console.log('Finished generating lines');
  passThrough.end();
  console.log('End of test');
});

const server = app.listen(port,'0.0.0.0', () => {
  console.log(`Server running on port ${port}`);
});

// Increase server timeout to 10 minutes.
server.requestTimeout = 600000;