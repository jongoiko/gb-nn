local TEST_SET_PATH <const> = "nn-training/test_set.txt"
local ROM_SYMBOLS_PATH <const> = "dist/gb-nn.sym"

local IMAGE_PIXELS_RAM_SYMBOL_NAME <const> = "wDigitPixels"
local FORWARD_PASS_RUNNING_RAM_SYMBOL_NAME <const> = "wNeuralNetworkForwardPassRunning"
local PREDICTED_DIGIT_RAM_SYMBOL_NAME <const> = "wPredictedDigit"

function main()
	local testImagesFile = io.open(TEST_SET_PATH, "r")
	if testImagesFile == nil then
		console:error("The file with the test image data (" .. TEST_SET_PATH .. ") could not be opened.")
		return
	end
	local romSymbolsFile = io.open(ROM_SYMBOLS_PATH, "r")
	if romSymbolsFile == nil then
		console:error("The ROM symbol file (" .. ROM_SYMBOLS_PATH .. ") could not be opened.")
		return
	end
	local symbols = readROMSymbols(romSymbolsFile)
	io.close(romSymbolsFile)
	console:log("Starting evaluation.")
	local lines = testImagesFile:lines()
	local totalImagesCount = 0
	local correctImagesCount = 0
	emu:reset()
	for i = 1, 10 do
		emu:runFrame()
	end
	for line in lines do
		totalImagesCount = totalImagesCount + 1
		local imagePixels = line:sub(1, #line - 1)
		local imageClass = tonumber(line:sub(#line))
		local predictedClass = predict(imagePixels, symbols)
		if predictedClass == imageClass then
			correctImagesCount = correctImagesCount + 1
		end
	end
	io.close(testImagesFile)
	local accuracyPercentage = 100 * correctImagesCount / totalImagesCount
	console:log("Evaluation finished. Accuracy: " .. accuracyPercentage .. "%")
end

function readROMSymbols(romSymbolsFile)
	local symbols = {}
	local lines = romSymbolsFile:lines()
	for line in lines do
		local hexAddress, symbolName = line:sub(4, 7), line:sub(9)
		local address = tonumber("0x" .. hexAddress)
		symbols[symbolName] = address
	end
	return symbols
end

function predict(imagePixels, romSymbols)
	local imagePixelsRAMAddress = romSymbols[IMAGE_PIXELS_RAM_SYMBOL_NAME]
	for pixelIndex = 1, #imagePixels do
		local pixelValue = tonumber(imagePixels:sub(pixelIndex, pixelIndex))
		emu:write8(imagePixelsRAMAddress + pixelIndex - 1, pixelValue)
	end
	emu:setKeys(1 << C.GB_KEY.START)
	for i = 1, 10 do
		emu:runFrame()
	end
	emu:setKeys(0)
	local forwardPassRunningRAMAddress = romSymbols[FORWARD_PASS_RUNNING_RAM_SYMBOL_NAME]
	while emu:read8(forwardPassRunningRAMAddress) ~= 0 do
		emu:runFrame()
	end
	local predictedDigitRAMAddress = romSymbols[PREDICTED_DIGIT_RAM_SYMBOL_NAME]
	local predictedDigit = emu:read8(predictedDigitRAMAddress)
	return predictedDigit
end

if emu then
	main()
else
	console:error("The ROM is not loaded. Make sure to load the gb-nn.gb ROM before running the script.")
end
