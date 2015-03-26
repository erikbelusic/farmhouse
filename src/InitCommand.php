<?php namespace Laravel\Farmhouse;

use Symfony\Component\Process\Process;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class InitCommand extends Command {

	/**
	 * Configure the command options.
	 *
	 * @return void
	 */
	protected function configure()
	{
		$this->setName('init')
                  ->setDescription('Create a stub Farmhouse.yaml file');
	}

	/**
	 * Execute the command.
	 *
	 * @param  \Symfony\Component\Console\Input\InputInterface  $input
	 * @param  \Symfony\Component\Console\Output\OutputInterface  $output
	 * @return void
	 */
	public function execute(InputInterface $input, OutputInterface $output)
	{
		if (is_dir(farmhouse_path()))
		{
			throw new \InvalidArgumentException("Farmhouse has already been initialized.");
		}

		mkdir(farmhouse_path());

		copy(__DIR__.'/stubs/Farmhouse.yaml', farmhouse_path().'/Farmhouse.yaml');
		copy(__DIR__.'/stubs/after.sh', farmhouse_path().'/after.sh');
		copy(__DIR__.'/stubs/aliases', farmhouse_path().'/aliases');

		$output->writeln('<comment>Creating Farmhouse.yaml file...</comment> <info>✔</info>');
		$output->writeln('<comment>Farmhouse.yaml file created at:</comment> '.farmhouse_path().'/Farmhouse.yaml');
	}

}
