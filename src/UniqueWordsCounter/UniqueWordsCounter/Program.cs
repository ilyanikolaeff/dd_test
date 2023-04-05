using System.Collections.Concurrent;
using System.Text.RegularExpressions;

namespace UniqueWordsCounter
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var parallelFileReader = new ParallelFileReader(new SimpleConsoleLogger());
            parallelFileReader.ReadAndProcess("source.txt");
            Console.Write("Processing finished. Press any key to exit");
            Console.ReadKey();
        }
    }

    internal class SimpleConsoleLogger
    {
        public void Log(string message)
        {
            Console.WriteLine($"[{DateTime.Now.ToLongTimeString()}] {message}");
        }
    }

    internal class ParallelFileReader
    {
        private readonly SimpleConsoleLogger _logger;
        public ParallelFileReader(SimpleConsoleLogger simpleLogger)
        {
            _logger = simpleLogger;
        }
        public void ReadAndProcess(string fileName)
        {
            var stringBuffer = new BlockingCollection<string>();
            Task.WaitAll(new Task[] { StartReader(fileName, stringBuffer), StartProcessing(stringBuffer) });
        }

        private Task StartReader(string fileName, BlockingCollection<string> stringBuffer)
        {
            return Task.Run(() =>
            {
                _logger.Log("Starting reading");
                using (var streamReader = new StreamReader(fileName))
                {
                    string currentLine;
                    while ((currentLine = streamReader.ReadLine()) != null)
                    {
                        stringBuffer.Add(currentLine);
                    }
                }
                stringBuffer.CompleteAdding();
                _logger.Log("Reading finished");
            });
        }

        private Task StartProcessing(BlockingCollection<string> stringBuffer)
        {
            return Task.Run(() =>
            {
                _logger.Log("Starting processing");
                var parallelOptions = new ParallelOptions { MaxDegreeOfParallelism = Environment.ProcessorCount };
                var wordsCounter = new ConcurrentDictionary<string, int>();
                var wordRegex = new Regex(@"\p{L}+", RegexOptions.Compiled); // any word in any language

                Parallel.ForEach(stringBuffer.GetConsumingEnumerable(), parallelOptions, line =>
                {
                    foreach (Match match in wordRegex.Matches(line))
                    {
                        wordsCounter.AddOrUpdate(match.Value, 1, (word, currentValue) => currentValue + 1);
                    }
                });
                WriteToFile(wordsCounter);
                _logger.Log("Processing finished");
            });
        }

        private void WriteToFile(IEnumerable<KeyValuePair<string, int>> dictionary)
        {
            using (var streamWriter = new StreamWriter("output.txt", false))
            {
                foreach (var pair in dictionary.OrderByDescending(s => s.Value)) 
                {
                    streamWriter.WriteLine(string.Concat(pair.Key, " = ", pair.Value));
                }
            }
        }
    }
}