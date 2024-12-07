const { ethers, artifacts } = require("hardhat");

async function main() {

    const [deployer] = await ethers.getSigners();

    const feeData = await ethers.provider.getFeeData();

    const baseFee = feeData.lastBaseFeePerGas.mul(ethers.utils.parseUnits("2", 0));
    const priorityFeePerGas = feeData.maxPriorityFeePerGas;

    const costLimit = {
        maxFeePerGas: baseFee.add(priorityFeePerGas),
      	maxPriorityFeePerGas: priorityFeePerGas,
        gasLimit: 5000000
    };

    const NftFastSwapForSwapV3 = await ethers.getContractFactory("NftFastSwapForSwapV3");
    const impl = await NftFastSwapForSwapV3.deploy(costLimit);
    console.log("impl", impl.address);
    return;

    const NftFastSwapForSwapV3Abi = await artifacts.readArtifact("NftFastSwapForSwapV3");
	const iface = new ethers.utils.Interface(NftFastSwapForSwapV3Abi.abi);
    // mainnet
    // const proxyAdmin = "0xadE812FC7B63C7AE6775F67B711c34bAbEccE36B";
    // const fastSwapArgs = {
    //     owner: deployer.address,
    //     uniswapRouter: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45",
    //     quoter: "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",
    //     pieceFactory: "0x82cAC2725345EA95A200187aE9A5506E48fe1C5d",
    //     nftSale: "0x2c3d85f7C4cBA8BfD937351b687b0B78a4a86A3F",
    //     approveTrade: "0xFfC0cB18D9b0f1ADc5CAe87B30b0d38EDFBd64b1"
    // };
    // sepolia
    // nftFastswap 0xf33Bb5Cd5c5e1189c4Fe39dE8ae4e83Fbf276eAd
    const proxyAdmin = "0x653C82d1EC399bDadeAC684e5BEAD1a58ada0d75";
    const fastSwapArgs = {
        owner: deployer.address,
        uniswapRouter: "0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E",
        quoter: "0xA669cb8513ED619975b1A6eE483907835FcD4223",
        pieceFactory: "0x5eD714c42E57f1dCD3b99F3678D337844D815897",
        nftSale: "0x06a022db1B4c5cDC5aCeE4FA36d5EE5A16c036e7",
        approveTrade: "0xbc42DC9fa37EF6F70060d5e7ea2756A106B692E4"
    };

	const data = iface.encodeFunctionData("initialize", [
        fastSwapArgs.owner,
        fastSwapArgs.uniswapRouter,
        fastSwapArgs.quoter,
        fastSwapArgs.pieceFactory,
        fastSwapArgs.nftSale,
        fastSwapArgs.approveTrade
	]);

    
    const TransparentUpgradeableProxy = await ethers.getContractFactory("TransparentUpgradeableProxy");
    const proxy = await TransparentUpgradeableProxy.deploy(impl.address, proxyAdmin, data, costLimit);
    console.log("proxy", proxy.address);

    // nftSale.grantRole(0x1a82baf2b928242f69f7147fb92490c6288d044f7257b88817e6284f1eec0f15, nftFastswap)
    console.log("finished");
}

main()
.then(() => process.exit(0))
.catch(error => {
    console.error(error);
    process.exit(1);
});