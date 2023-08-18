import { deployConnector } from "./deployConnector";

async function main() {
  if (process.env.connectorName) {
    await deployConnector();
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
