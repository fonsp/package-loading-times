// This Netlify Function serves a JSON file index.
// Looks like:
/*

{
  "files": [
    "2025-04-14_10-54-53-231_julia_1.9.4/pkg_load_times.toml",
    "2025-04-14_10-54-53-231_julia_1.9.4/top_packages_sorted.txt",
    "2025-04-14_10-54-53-231_julia_1.9.4/top_packages_sorted_with_deps.txt",
    "2025-04-14_10-54-53-757_julia_1.10.9/pkg_load_times.toml",
  ]
}
*/


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

    // Restrict scanning to directories within the workspace
    const workspaceDirs = fs.readdirSync(baseDir, { withFileTypes: true })
      .filter(entry => entry.isDirectory() && !entry.name.startsWith('.')) // Exclude hidden/system directories
      .map(entry => path.join(baseDir, entry.name));

    

    const files = workspaceDirs.flatMap(dir => getFilePaths(dir));
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