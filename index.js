const pinataSDK = require("@pinata/sdk");
require("dotenv").config();
const fs = require("fs");
const pinata = new pinataSDK(
  process.env.PINATA_API,
  process.env.PINATA_API_SECRET
);

const readableStreamForFile = fs.createReadStream("./images/Universe.jpg");
const options = {
  pinataMetadata: {
    name: "My New NFT",
    keyvalues: {
      customKey: "customValue",
      customKey2: "customValue2",
    },
  },
  pinataOptions: {
    cidVersion: 0,
  },
};

const pinFileToIPFS = () => {
  return pinata
    .pinFileToIPFS(readableStreamForFile, options)
    .then((result) => {
      return `https://gateway.pinata.cloud/ipfs/${result.IpfsHash}`;
    })
    .catch((err) => {
      console.log(err);
    });
};

const pinJSONToIPFS = (body) => {
    return pinata
  .pinJSONToIPFS(body, options)
  .then((result) => {
    return `https://gateway.pinata.cloud/ipfs/${result.IpfsHash}`
  })
  .catch((err) => {
    console.log(err);
  });
}



const getMetadata = async () => {
  const imageUrl = await pinFileToIPFS();
  const body = {
    name: "My new NFT",
    description: "This is my new NFT collection",
    image: imageUrl,
  };

  const metadata = await pinJSONToIPFS(body);
  console.log(metadata);
};
getMetadata();


//  https://gateway.pinata.cloud/ipfs/QmdGfTRq7CdfjcXt4ZHKgm4qBiCpP4BWqoQDN6Fnf9V2X6
//  https://gateway.pinata.cloud/ipfs/Qmdx37SzuUcXyZDeNUdYNferNLQ6TGJTkweg7o4ZTv2XeQ
//  https://gateway.pinata.cloud/ipfs/QmQ6sH4Hnc29bJAH4tpCmaVSdj7a1mNGCba4z51mBSnyFx