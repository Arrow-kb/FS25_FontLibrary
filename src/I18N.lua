I18N.formatMoney = Utils.overwrittenFunction(I18N.formatMoney, function(self, superFunc, amount, maxAmount, displayCurrencySymbol, currencySymbolAsPrefix)

	local money = superFunc(self, amount, maxAmount, displayCurrencySymbol, currencySymbolAsPrefix)
	money = string.gsub(money, "\194", "")

	return money

end)


I18N.getCurrencySymbol = Utils.overwrittenFunction(I18N.getCurrencySymbol, function(self, superFunc, isShort)

	local symbol = superFunc(self, isShort)
	symbol = string.gsub(symbol, "\194", "")

	return symbol

end)