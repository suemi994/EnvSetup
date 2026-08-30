/**
 * HUD 插件：在 Line 1 显示 [模型名] · thinking 档位。
 *
 * 注意：经典模式下插件元素追加在行尾（context bar/耗时之后），
 * 无法前置到 context bar 前面 —— 那是 hud-footer.ts 的代码结构限制。
 * 若要前置只能走网格布局（layout + placement 钉列）或修改包源码。
 */
export default {
	name: "session-model",
	target: "line1",
	order: 90,
	render(ctx, theme) {
		const parts: string[] = [];
		if (ctx.model) {
			parts.push(theme.fg("accent", `[${ctx.model.id}]`));
		}
		if (ctx.model?.reasoning && ctx.thinking && ctx.thinking !== "off") {
			parts.push(theme.fg("dim", `· ${ctx.thinking}`));
		}
		return parts.length > 0 ? parts.join(" ") : undefined;
	},
};
