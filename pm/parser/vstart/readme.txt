-- 分析脚本的目录 --

分析脚本 ：parser_start.sh    运行时无参数

配置文件 ：

EngineConfig.pm   --对每一种采集到的文件作分析   若有新类型的采集文件生成  要在此配置   .raw 到 .pif
UserConfig.pm     --配置从 .pif 到 .lif 的文件