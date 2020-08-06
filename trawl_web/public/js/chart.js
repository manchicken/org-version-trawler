const colorValue = (index) => Math.floor(Math.random() * 200 + 30);

const startingColor = [230, 210, 190].map((x) => colorValue(x));
const resetColorValue = 220;
const getNextColorRGBA = (last) => [
  last[2] <= 0 ? resetColorValue : colorValue(last[2]),
  last[0],
  last[1],
];
const getColors = (prev, one) => {
  if (one <= 0) return [prev, getNextColorRGBA(prev)];
  const a = getNextColorRGBA(prev);
  return [a, ...getColors(a, one - 1)];
};

const getChartColors = (count) =>
  getColors(startingColor, count).map((x) => `rgb(${x[0]},${x[1]},${x[2]})`);
