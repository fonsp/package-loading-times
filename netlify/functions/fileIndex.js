const fs = require('fs');
const path = require('path');

// Helper function to recursively get file paths
function getFilePaths(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = entries
    .filter(file => !file.isDirectory())
    .map(file => path.join(dir, file.name)); // Use .name to get the string path
  const folders = entries.filter(folder => folder.isDirectory());

  for (const folder of folders) {
    files.push(...getFilePaths(path.join(dir, folder.name))); // Use .name here as well
  }

  return files;
}

exports.handler = async () => {
  try {
    const baseDir = path.resolve(__dirname, '../../'); // Adjust to your workspace root
    const files = getFilePaths(baseDir);
    const relativeFiles = files.map(file => path.relative(baseDir, file));

    return {
      statusCode: 200,
      body: JSON.stringify({ files: relativeFiles }, null, 2),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};