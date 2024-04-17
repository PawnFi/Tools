const { ethers, artifacts } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();

    const feeData = await ethers.provider.getFeeData();

    const costLimit = {
        maxFeePerGas: feeData.maxFeePerGas,
      	maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
        gasLimit: 3500000
    };

    const NftFastSwapForSwapV3 = await ethers.getContractFactory("NftFastSwapForSwapV3");
    const contract = await NftFastSwapForSwapV3.deploy(costLimit);
    console.log("NftFastSwapForSwapV3: ", contract.address);
    console.log("finished");
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});