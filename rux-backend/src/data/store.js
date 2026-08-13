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

const cloneDefault = (name) => JSON.parse(JSON.stringify(defaults[name]));
const collectionLocks = new Map();

const withCollectionLock = (name, operation) => {
    const previousOperation = collectionLocks.get(name) || Promise.resolve();
    const nextOperation = previousOperation.then(operation, operation);
    collectionLocks.set(name, nextOperation.catch(() => {}));
    return nextOperation;
};

async function ensureCollection(name) {
    const filePath = files[name];
    await fs.mkdir(dataDirectory, { recursive: true });

    try {
        await fs.access(filePath);
    } catch {
        await fs.writeFile(filePath, JSON.stringify(cloneDefault(name), null, 2));
    }
}

async function readCollectionFile(name) {
    await ensureCollection(name);
    const filePath = files[name];
    const raw = await fs.readFile(filePath, 'utf8');

    try {
        return JSON.parse(raw);
    } catch {
        const fallbackValue = cloneDefault(name);
        await fs.writeFile(filePath, JSON.stringify(fallbackValue, null, 2));
        return fallbackValue;
    }
}

async function writeCollectionFile(name, value) {
    await ensureCollection(name);
    await fs.writeFile(files[name], JSON.stringify(value, null, 2));
    return value;
}

async function readCollection(name) {
    return withCollectionLock(name, async () => readCollectionFile(name));
}

async function writeCollection(name, value) {
    return withCollectionLock(name, async () => writeCollectionFile(name, value));
}

async function updateCollection(name, updater) {
    return withCollectionLock(name, async () => {
        const currentValue = await readCollectionFile(name);
        const updatedValue = await updater(currentValue);
        return writeCollectionFile(name, updatedValue);
    });
}

module.exports = {
    readCollection,
    writeCollection,
    updateCollection
};
