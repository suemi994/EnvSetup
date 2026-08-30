/**
 * HUD 插件：在 Line 2 显示 git 分支 + 项目名。
 *
 * 注意：经典模式下插件元素追加在行尾（context files 之后），
 * 无法前置到 context files 前面 —— 那是 hud-footer.ts 的代码结构限制。
 * 若要前置只能走网格布局（layout + placement 钉列）或修改包源码。
 */
export default {
	name: "session-git",
	target: "line2",
	order: 90,
	render(ctx, theme) {
		const parts: string[] = [];
		if (ctx.branch) {
			parts.push(theme.fg("dim", `git:(${ctx.branch})`));
		}
		if (ctx.projectName) {
			parts.push(theme.fg("dim", ctx.projectName));
		}
		return parts.length > 0 ? parts.join(" · ") : undefined;
	},
};
