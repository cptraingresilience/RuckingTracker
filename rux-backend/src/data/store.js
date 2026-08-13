const fs = require('fs/promises');
const path = require('path');

const dataDirectory = process.env.DATA_DIR
    ? path.resolve(process.env.DATA_DIR)
    : path.join(__dirname, '../../data');

const files = {
    users: path.join(dataDirectory, 'users.json'),
    activities: path.join(dataDirectory, 'activities.json'),
    teams: path.join(dataDirectory, 'teams.json')
};

const defaults = {
    users: [],
    activities: [],
    teams: [
        { id: 'team-oda-555', name: 'ODA 555', members: [] },
        { id: 'team-tx-sfm', name: 'TX Special Forces Mentorship', members: [] },
        { id: 'team-drinking-crew', name: 'Drinking Crew', members: [] },
        { id: 'team-go-ruck-friends', name: 'Go Ruck Friends', members: [] }
    ]
};

async function ensureCollection(name) {
    const filePath = files[name];
    await fs.mkdir(dataDirectory, { recursive: true });

    try {
        await fs.access(filePath);
    } catch {
        await fs.writeFile(filePath, JSON.stringify(defaults[name], null, 2));
    }
}

async function readCollection(name) {
    await ensureCollection(name);
    const filePath = files[name];
    const raw = await fs.readFile(filePath, 'utf8');

    try {
        return JSON.parse(raw);
    } catch {
        await fs.writeFile(filePath, JSON.stringify(defaults[name], null, 2));
        return defaults[name];
    }
}

async function writeCollection(name, value) {
    await ensureCollection(name);
    await fs.writeFile(files[name], JSON.stringify(value, null, 2));
    return value;
}

module.exports = {
    readCollection,
    writeCollection
};
