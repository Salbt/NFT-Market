import { create } from 'kubo-rpc-client';
import fs from 'fs';

require('dotenv').config('./.env');

const ipfs = create(new URL(process.env.IPFS_URL));

export async function addJSONToIPFS(json) {
    try {
        const result = await ipfs.add(JSON.stringify(json));
        return result;
    }catch (error) {
        console.error('Error uploading JSON to IPFS:', error);
    }
}

export async function addFileToIPFS(feilPath) {
    try {
        const file = fs.readFileSync(feilPath);
        const result = await ipfs.add({
            path: feilPath,
            content: file
        });
        return result;
    }catch (error) {
        console.error('Error uploading file to IPFS:', error);
    }
}
