/// Characters of the old HSK (2.0) word lists, levels 1 to 3: each level
/// holds only the characters that no lower level has (docs/PLAN.md,
/// Build 1C, Must 4). A paper character outside the lists up to the
/// paper's level flags the question: a misread look-alike, a traditional
/// form, or a name or place (accepted).
///
/// Source: https://github.com/drkameleon/complete-hsk-vocabulary (MIT
/// licence), files wordlists/exclusive/old/1.min.json, 2.min.json and
/// 3.min.json, fetched 2026-11-18; the characters of every word (field
/// `s`), in list order, without repeats. Levels 1-3: 150, 147
/// and 298 words; 178, 168 and 272 new characters.
abstract final class HskCharacters {
  static const level1 =
      '爱八爸杯子北京本不客气菜茶吃出租车打电话大的点脑视影东西都读对起多少儿二饭馆飞机分钟高兴个工作狗汉语好喝和很后面回会火站'
      '几家叫今天九开看见块来老师了冷里零六妈吗买猫没关系米名字明哪那呢能你年女朋友漂亮苹果七前钱请去热人认识日三商店上午什么十'
      '时候是书谁水睡觉说四岁他她太听同学喂我们五喜欢下雨先生现在想小姐些写谢星期习校一衣服医院椅有月再怎样这中国住桌昨坐做';

  static const level2 =
      '吧白百帮助报纸比便宜别唱歌穿船次从错篮球但到得弟第懂房间非常务员告诉哥给公共汽斤司贵还孩号黑红迎答场鸡蛋件教室介绍近进就'
      '咖啡始考试可以课快乐累离两路旅游卖慢忙每妹门男您牛奶旁边跑步票妻床千晴让班身体病事情手表送所它踢题跳舞外完玩晚为问希望洗'
      '瓜向笑新姓休息雪颜色眼睛羊肉药要也已经意思因阴泳右鱼元远运动早张长丈夫找着真正知道准备自行走最左';

  static const level3 =
      '阿姨啊矮安静把搬办法半包饱方被鼻较赛必须变化示演宾冰箱才单参加草层差超市衬衫成绩城迟除厨春词聪扫算带担心糕当然地铁图灯低'
      '梯冬物短段锻炼饿而且耳朵发烧放附复敢感冒干净刚根据跟更园故刮于汁过害怕河板护照花画坏环境换黄议或者极乎记季节检查简健康讲'
      '角脚接街目结婚束解决借理久旧举句定渴刻空调口哭裤筷蓝礼历史脸练辆邻居楼绿马满帽条拿南难级轻鸟努力爬山盘胖啤酒葡萄普通其实'
      '奇怪骑铅笔清楚秋裙容易如伞网声音使世界瘦叔舒树数刷双平虽阳糖特疼提育甜头突腿碗万忘位文惯澡夏相信香蕉像鞋闻鲜李趣熊需选择'
      '镜求爷般直银应该响用戏又遇愿越云顾片急只终种重周末主注祝典己总业';

  /// The highest level with a list; above it nothing is checked.
  static const highestLevel = 3;

  static final Map<int, Set<String>> _upTo = {};

  /// Every character up to [level] (1-3); null when there is no list.
  static Set<String>? upTo(int level) {
    if (level < 1 || level > highestLevel) return null;
    return _upTo.putIfAbsent(level, () {
      final text = [level1, level2, level3].take(level).join();
      return {for (final r in text.runes) String.fromCharCode(r)};
    });
  }

  static final _hanzi = RegExp(r'[\u3400-\u9fff]');

  /// Chinese characters of [text] outside the lists up to [level], in
  /// order, without repeats. Empty when the level has no list.
  static List<String> outside(String text, int level) {
    final known = upTo(level);
    if (known == null) return const [];
    final out = <String>[];
    for (final r in text.runes) {
      final c = String.fromCharCode(r);
      if (_hanzi.hasMatch(c) && !known.contains(c) && !out.contains(c)) out.add(c);
    }
    return out;
  }
}
