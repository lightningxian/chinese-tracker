// Practice HSK 3 paper for measuring the built-in reader (docs/PLAN.md,
// Build 1C, Must 1a). Every sentence here was made up for this file; it
// follows the public HSK 3 format (80 questions, the same parts) but copies
// no real paper. Loaded by paper.html (draws the pages) and by build.mjs
// (writes the truth file).
(function (root) {
  const PAPER = {
    code: 'H399001P',
    level: 3,
    watermark: '易华练习',
    blocks: [
      // 一、听力
      {kind: 'skill', text: '一、听力'},
      {kind: 'part', text: '第一部分'},
      {
        kind: 'pictures', start: 1, end: 5,
        pictures: ['house', 'tree', 'cup', 'car', 'sun', 'book'],
        example: ['例如：男：你最喜欢什么运动？', '女：我最喜欢踢足球。'],
      },
      {
        kind: 'pictures', start: 6, end: 10,
        pictures: ['umbrella', 'clock', 'fish', 'bike', 'ball'],
        example: [],
      },
      {kind: 'part', text: '第二部分'},
      {
        kind: 'statements', start: 11, end: 20,
        example: ['例如：★ 他打算下午去银行。（√）'],
        items: [
          '他今天没去上班。',
          '那家饭馆的菜很便宜。',
          '妹妹喜欢画画儿。',
          '他们下个月去旅游。',
          '小王的电脑坏了。',
          '这本书是爸爸买的。',
          '今天的天气比昨天冷。',
          '她每天骑自行车上学。',
          '会议已经结束了。',
          '他打算明年学开车。',
        ],
      },
      {kind: 'part', text: '第三部分'},
      {
        kind: 'choices', start: 21, end: 30,
        example: ['例如：男：小王，帮我开一下门，好吗？谢谢！', '问：男的想让小王做什么？', 'A 开门 B 拿东西 C 去超市'],
        items: [
          ['在家', '在学校', '在医院'],
          ['八点', '九点半', '十点'],
          ['很高兴', '很生气', '很累'],
          ['坐公共汽车', '打车', '走路'],
          ['一百块', '两百块', '三百块'],
          ['银行', '超市', '图书馆'],
          ['同学', '邻居', '老师'],
          ['喝咖啡', '看电影', '去游泳'],
          ['星期一', '星期三', '星期五'],
          ['头疼', '发烧', '感冒了'],
        ],
      },
      {kind: 'part', text: '第四部分'},
      {
        kind: 'choices', start: 31, end: 40,
        example: ['例如：女：晚饭做好了，准备吃饭了。', '问：他们最可能在哪儿？', 'A 教室 B 机场 C 家里'],
        items: [
          ['买衣服', '买水果', '买鞋'],
          ['他太忙了', '他生病了', '他忘了'],
          ['公园', '机场', '火车站'],
          ['红色', '蓝色', '黄色'],
          ['妈妈', '姐姐', '奶奶'],
          ['去北京', '去上海', '回家'],
          ['太远了', '太贵了', '太小了'],
          ['跳舞', '唱歌', '踢足球'],
          ['半个小时', '一个小时', '两个小时'],
          ['洗衣服', '做饭', '打扫房间'],
        ],
      },
      // 二、阅读
      {kind: 'between', text: '下面是阅读部分'},
      {kind: 'skill', text: '二、阅读'},
      {kind: 'part', text: '第一部分'},
      {
        kind: 'matching', start: 41, end: 45,
        options: [
          '你别着急，我们还有十分钟。',
          '这个周末我想去爬山，你一起去吗？',
          '我觉得这件衣服有点儿大。',
          '他是我的中学同学，我们认识十年了。',
          '当然可以，你先坐一下。',
          '我已经吃过了，你们吃吧。',
        ],
        example: ['例如：你好，我可以进来吗？ （ E ）'],
        items: [
          '那你试试小一点儿的吧。',
          '好啊，我们几点出发？',
          '快点儿吧，电影马上就要开始了。',
          '晚饭好了，快过来吃吧。',
          '你们两个人是怎么认识的？',
        ],
      },
      {
        kind: 'matching', start: 46, end: 50,
        options: [
          '我的手机找不到了。',
          '明天会下大雨。',
          '这里的东西又好吃又便宜。',
          '你的汉语说得越来越好了。',
          '我们班有二十个学生。',
        ],
        example: [],
        items: [
          '谢谢，我每天都练习。',
          '那我们别去公园了。',
          '你再找找，是不是在书包里？',
          '难怪这家店的客人这么多。',
          '其中有一半是女生。',
        ],
      },
      {kind: 'part', text: '第二部分'},
      {
        kind: 'wordbank', start: 51, end: 55,
        options: ['地方', '突然', '认真', '健康', '声音', '简单'],
        example: ['例如：这个孩子唱歌的（ E ）真好听。'],
        items: [
          ['这道题很（ ），我一分钟就做完了。'],
          ['他学习非常（ ），每天都复习。'],
          ['你知道附近有什么好玩的（ ）吗？'],
          ['我正在看书，（ ）停电了。'],
          ['多运动对（ ）有好处。'],
        ],
      },
      {
        kind: 'wordbank', start: 56, end: 60,
        options: ['留学', '照顾', '清楚', '结婚', '决定', '方便'],
        example: ['例如：A：你（ E ）了吗？', 'B：还没有，我再想想。'],
        items: [
          ['A：你听（ ）了吗？', 'B：没有，请你再说一遍。'],
          ['A：我们坐地铁去吧，很（ ）。', 'B：好的，我们走吧。'],
          ['A：你哥哥明年去哪儿（ ）？', 'B：他想去中国。'],
          ['A：你出去玩的时候，谁（ ）你的小狗？', 'B：我的邻居。'],
          ['A：他们什么时候（ ）？', 'B：听说是十月。'],
        ],
      },
      {kind: 'part', text: '第三部分'},
      {
        kind: 'passages', start: 61, end: 70,
        example: ['例如：您是来参加今天会议的吗？您来早了一点儿，现在才八点半。', '★ 会议最可能几点开始？', 'A 8点 B 8点半 C 9点'],
        items: [
          {passage: '我家离公司不远，每天走路去上班，只要十五分钟。', question: '他怎么去上班？', options: ['走路', '坐车', '骑车']},
          {passage: '今天是妈妈的生日，我和姐姐准备给她做一个蛋糕。', question: '他们要做什么？', options: ['买花', '做蛋糕', '唱歌']},
          {passage: '小李上个星期感冒了，没来上课，今天他终于来了。', question: '小李上个星期怎么了？', options: ['去旅游了', '感冒了', '搬家了']},
          {passage: '这家商店周末人很多，所以我一般星期二去买东西。', question: '他一般什么时候去买东西？', options: ['星期二', '星期六', '星期天']},
          {passage: '我弟弟很喜欢动物，他家里有两只猫和一只狗。', question: '弟弟家有几只猫？', options: ['一只', '两只', '三只']},
          {passage: '学好一门外语需要时间，每天听一听、说一说，慢慢就会进步。', question: '学外语要注意什么？', options: ['每天练习', '只看书', '多休息']},
          {passage: '王老师教我们数学，她上课很有意思，同学们都很喜欢她。', question: '王老师教什么？', options: ['历史', '数学', '音乐']},
          {passage: '冬天快到了，天气越来越冷，出门的时候要多穿点儿衣服。', question: '现在可能是什么季节？', options: ['春天', '夏天', '秋天']},
          {passage: '我昨天晚上睡得太晚了，今天早上差点儿迟到。', question: '他今天早上怎么了？', options: ['迟到了', '差点儿迟到', '没起床']},
          {passage: '这个房间又干净又安静，离地铁站也很近，就是有点儿小。', question: '这个房间有什么问题？', options: ['不干净', '太吵', '有点儿小']},
        ],
      },
      // 三、书写
      {kind: 'between', text: '下面是书写部分'},
      {kind: 'skill', text: '三、书写'},
      {kind: 'part', text: '第一部分'},
      {
        kind: 'reorder', start: 71, end: 75,
        example: ['例如：小船 上 一 条 河 有', '河上有一条小船。'],
        // Pieces as printed (shuffled); the order is the answer key, not
        // part of what the reader must read.
        items: [
          ['桌子', '小猫', '下面', '在'],
          ['作业', '写完了', '我', '把'],
          ['一点儿', '比', '高', '我', '他'],
          ['有意思', '这本书', '非常'],
          ['窗户', '关上', '请你'],
        ],
      },
      {kind: 'part', text: '第二部分'},
      {
        kind: 'pinyin', start: 76, end: 80,
        example: ['例如：没（ ）系，别难过，高兴点儿。'],
        exampleHint: 'guān',
        items: [
          {pinyin: 'guān', sentence: '请把门（ ）上。'},
          {pinyin: 'chá', sentence: '我每天早上喝一杯（ ）。'},
          {pinyin: 'shù', sentence: '他在大（ ）下看书。'},
          {pinyin: 'mǎi', sentence: '你想（ ）什么？'},
          {pinyin: 'xué', sentence: '我在（ ）校吃午饭。'},
        ],
      },
    ],
  };

  if (typeof module !== 'undefined' && module.exports) module.exports = PAPER;
  else root.PAPER = PAPER;
})(typeof window !== 'undefined' ? window : globalThis);
